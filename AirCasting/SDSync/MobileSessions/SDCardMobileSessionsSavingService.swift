// Created by Lunar on 26/11/2021.
//

import Foundation
import CoreLocation
import Combine
import Resolver

protocol SDCardMobileSessionssSaver {
    func saveDataToDb(fileURL: URL, deviceID: String, completion: @escaping (Result<[SessionUUID], Error>) -> Void)
}

class SDCardMobileSessionsSavingService: SDCardMobileSessionssSaver {
    @Injected private var fileLineReader: FileLineReader
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    private let parser = SDCardMeasurementsParser()
    
    func saveDataToDb(fileURL: URL, deviceID: String, completion: @escaping (Result<[SessionUUID], Error>) -> Void) {
        var processedSessions = Set<SDSession>()
        var streamsWithMeasurements: [SDStream: [Measurement]] = [:]
        
        // We don't want to save data for session which have already been finished.
        // We only want to save measurements of new sessions or for sessions in standalone mode recorded with the syncing device
        var sessionsToIgnore: [SessionUUID] = []
        
        // TODO: Change it to not spend so much time inside accessStorage. Remove buffers, do everything ad-hoc, once per every file line
            do {
                // TODO: Why is reading file inside accessStorage? It can cause problems
                try self.fileLineReader.readLines(of: fileURL, progress: { line in
                    switch line {
                    case .line(let content):
                        let measurementsRow = self.parser.parseMeasurement(lineString: content) // linia danych (data, wartości itd.)
                        guard let measurements = measurementsRow, !sessionsToIgnore.contains(measurements.sessionUUID) else { return }
                        var session = processedSessions.first(where: { $0.uuid == measurements.sessionUUID })
                        if session == nil {
                            
                            session = self.processSession(sessionUUID: measurements.sessionUUID, deviceID: deviceID, sessionsToIgnore: &sessionsToIgnore)
                            
                            guard let createdSession = session else { return }
                            processedSessions.insert(createdSession)
                        }
                        
                        guard session!.lastMeasurementTime == nil || measurements.date > session!.lastMeasurementTime! else { return }
                        
                        // TODO: this causes a lot of memory usage:
                        self.enqueueForSaving(measurements: measurements, buffer: &streamsWithMeasurements)
                        
                        // test -- moving creating ad hoc
                        if session?.lastMeasurementTime == nil {
                            streamsWithMeasurements.keys.forEach { stream in
                                self.createSession(sdStream: stream,
                                                   location: .init(latitude: measurements.lat, longitude: measurements.long),
                                                   time: measurements.date)
                            }
                        }
                    case .endOfFile:
                        Log.info("Reached end of csv file")
                    }
                })
                
                self.saveData(streamsWithMeasurements, with: deviceID)
                completion(.success(Array(Set(streamsWithMeasurements.keys.map(\.sessionUUID)))))
            } catch {
                completion(.failure(error))
            }
    }
    
    private func saveData(_ streamsWithMeasurements: [SDStream: [Measurement]], with deviceID: String) {
        streamsWithMeasurements.forEach { (sdStream: SDStream, measurements: [Measurement]) in
            self.saveMeasurements(measurements: measurements, sdStream: sdStream, deviceID: deviceID)
            measurementStreamStorage.accessStorage { storage in
                do {
                    try storage.setStatusToFinishedAndUpdateEndTime(for: sdStream.sessionUUID, endTime: measurements.last?.time)
                } catch {
                    Log.info("Error setting status to finished and updating end time: \(error)")
                }
            }
        }
    }
    
    private func createSession(sdStream: SDStream, location: CLLocationCoordinate2D?, time: Date?) {
        measurementStreamStorage.accessStorage { storage in
            do {
                try storage.createSession(Session(uuid: sdStream.sessionUUID, type: .mobile, name: "Imported from SD card", deviceType: .AIRBEAM3, location: location, startTime: time))
            } catch {
                Log.error("Couldn't create session: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveMeasurements(measurements: [Measurement], sdStream: SDStream, deviceID: String) {
        measurementStreamStorage.accessStorage { storage in
            do {
                var existingStreamID = try storage.existingMeasurementStream(sdStream.sessionUUID, name: sdStream.name.rawValue)
                if existingStreamID == nil {
                    let measurementStream = self.createMeasurementStream(for: sdStream.name, sensorPackageName: deviceID)
                    existingStreamID = try storage.saveMeasurementStream(measurementStream, for: sdStream.sessionUUID)
                }
                try storage.addMeasurements(measurements, toStreamWithID: existingStreamID!)
            } catch {
                Log.info("Saving measurements failed: \(error)")
            }
        }
    }
    
    private func processSession(sessionUUID: SessionUUID, deviceID: String, sessionsToIgnore: inout [SessionUUID]) -> SDSession? {
        var session: SessionEntity?
        measurementStreamStorage.accessStorage { storage in
            session = try? storage.getExistingSession(with: sessionUUID)
        }
        if let existingSession = session {
            guard existingSession.isInStandaloneMode && existingSession.sensorPackageName == deviceID else {
                Log.info("[SD SYNC] Ignoring session \(existingSession.name ?? "none")")
                sessionsToIgnore.append(sessionUUID)
                return nil
            }
            return SDSession(uuid: sessionUUID, lastMeasurementTime: existingSession.lastMeasurementTime)
        } else {
            return SDSession(uuid: sessionUUID, lastMeasurementTime: nil)
        }
    }
    
    private func enqueueForSaving(measurements: SDCardMeasurementsRow, buffer streamsWithMeasurements: inout [SDStream: [Measurement]]) {
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .f, header: .f), default: []].append(Measurement(time: measurements.date, value: measurements.f, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .rh, header: .rh), default: []].append(Measurement(time: measurements.date, value: measurements.rh, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm1, header: .pm1), default: []].append(Measurement(time: measurements.date, value: measurements.pm1, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm2_5, header: .pm2_5), default: []].append(Measurement(time: measurements.date, value: measurements.pm2_5, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm10, header: .pm10), default: []].append(Measurement(time: measurements.date, value: measurements.pm10, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
    }
    
    private func createMeasurementStream(for sensorName: MeasurementStreamSensorName, sensorPackageName: String) -> MeasurementStream {
        MeasurementStream(sensorName: sensorName, sensorPackageName: sensorPackageName)
    }
}
