// Created by Lunar on 26/11/2021.
//

import Foundation
import CoreLocation
import Combine

protocol SDCardMobileSessionssSaver {
    func saveDataToDb(fileURL: URL, deviceID: String)
}

class SDCardMobileSessionsSavingService: SDCardMobileSessionssSaver {
    private let fileLineReader: FileLineReader
    private let measurementStreamStorage: MeasurementStreamStorage
    private let parser = SDCardMeasurementsParser()
    
    init(measurementStreamStorage: MeasurementStreamStorage, fileLineReader: FileLineReader) {
        self.measurementStreamStorage = measurementStreamStorage
        self.fileLineReader = fileLineReader
    }
    
    func saveDataToDb(fileURL: URL, deviceID: String) {
        var processedSessions = Set<SDSession>()
        var streamsWithMeasurements: [SDStream: [Measurement]] = [:]
        
        // We don't want to save data for session which have already been finished.
        // We only want to save measurements of new sessions or for sessions in standalone mode recorded with the syncing device
        var sessionsToCreate: [SessionUUID] = []
        var sessionsToIgnore: [SessionUUID] = []
        
        measurementStreamStorage.accessStorage { storage in
            do {
                try self.fileLineReader.readLines(of: fileURL, progress: { line in
                    switch line {
                    case .line(let content):
                        let measurementsRow = self.parser.parseMeasurement(lineSting: content)
                        guard let measurements = measurementsRow, !sessionsToIgnore.contains(measurements.sessionUUID) else { return }
                        
                        var session = processedSessions.first(where: { $0.uuid == measurements.sessionUUID })
                        if session == nil {
                            session = self.processSession(storage: storage, sessionUUID: measurements.sessionUUID, deviceID: deviceID, sessionsToIgnore: &sessionsToIgnore, sessionsToCreate: &sessionsToCreate)
                            guard session != nil else { return }
                            processedSessions.insert(session!)
                        }
                        
                        guard session!.lastMeasurementTime == nil || measurements.date > session!.lastMeasurementTime! else { return }
                        
                        self.enqueueForSaving(measurements: measurements, buffer: &streamsWithMeasurements)
                    case .endOfFile:
                        Log.info("Reached end of csv file")
                    }
                })
                self.saveData(streamsWithMeasurements, to: storage, with: deviceID, sessionsToCreate: &sessionsToCreate)
            } catch {
                Log.error("Error reading file")
            }
        }
    }
    
    private func read(fileURL: URL) -> PassthroughSubject<SDCardMeasurementsRow?, Error> {
        let publisher = PassthroughSubject<SDCardMeasurementsRow?, Error>()
        do {
            try fileLineReader.readLines(of: fileURL, progress: { line in
                switch line {
                case .line(let content):
                    let measurementsRow = parser.parseMeasurement(lineSting: content)
                    publisher.send(measurementsRow)
                case .endOfFile:
                    publisher.send(completion: .finished)
                }
            })
        } catch {
            Log.error("Cannot read file \(fileURL): \(error.localizedDescription)")
            publisher.send(completion: .failure(error))
        }
        return publisher
    }
    
    private func saveData(_ streamsWithMeasurements: [SDStream: [Measurement]], to storage: HiddenCoreDataMeasurementStreamStorage, with deviceID: String, sessionsToCreate: inout [SessionUUID]) {
        streamsWithMeasurements.forEach { (sdStream: SDStream, measurements: [Measurement]) in
            if sessionsToCreate.contains(sdStream.sessionUUID) {
                createSession(storage: storage, sdStream: sdStream, location: measurements.first?.location, time: measurements.first?.time, sessionsToCreate: &sessionsToCreate)
                saveMeasurements(measurements: measurements, storage: storage, sdStream: sdStream, deviceID: deviceID)
            } else {
                saveMeasurements(measurements: measurements, storage: storage, sdStream: sdStream, deviceID: deviceID)
                do {
                    try storage.setStatusToFinishedAndUpdateEndTime(for: sdStream.sessionUUID, endTime: measurements.last?.time)
                } catch {
                    Log.info("Error setting status to finished and updating end time: \(error)")
                }
            }
        }
    }
    
    private func createSession(storage: HiddenCoreDataMeasurementStreamStorage, sdStream: SDStream, location: CLLocationCoordinate2D?, time: Date?, sessionsToCreate: inout [SessionUUID]) {
        do {
            try storage.createSession(Session(uuid: sdStream.sessionUUID, type: .mobile, name: "Imported from SD card", deviceType: .AIRBEAM3, location: location, startTime: time))
            sessionsToCreate.removeAll(where: { $0 == sdStream.sessionUUID })
        } catch {
            Log.error("Couldn't create session: \(error.localizedDescription)")
        }
    }
    
    private func saveMeasurements(measurements: [Measurement], storage: HiddenCoreDataMeasurementStreamStorage, sdStream: SDStream, deviceID: String) {
        do {
            var existingStreamID = try storage.existingMeasurementStream(sdStream.sessionUUID, name: sdStream.name.rawValue)
            if existingStreamID == nil {
                let measurementStream = createMeasurementStream(for: sdStream.name, sensorPackageName: deviceID)
                existingStreamID = try storage.saveMeasurementStream(measurementStream, for: sdStream.sessionUUID)
            }
            try storage.addMeasurements(measurements, toStreamWithID: existingStreamID!)
        } catch {
            Log.info("Saving measurements failed: \(error)")
        }
    }
    
    private func processSession(storage: HiddenCoreDataMeasurementStreamStorage, sessionUUID: SessionUUID, deviceID: String, sessionsToIgnore: inout [SessionUUID], sessionsToCreate: inout [SessionUUID]) -> SDSession? {
        if let existingSession = try? storage.getExistingSession(with: sessionUUID) {
            guard existingSession.isInStandaloneMode && existingSession.sensorPackageName == deviceID else {
                Log.info("[SD SYNC] Ignoring session \(existingSession.name ?? "none")")
                sessionsToIgnore.append(sessionUUID)
                return nil
            }
            
            return SDSession(uuid: sessionUUID, lastMeasurementTime: existingSession.lastMeasurementTime)
        } else {
            sessionsToCreate.append(sessionUUID)
            return SDSession(uuid: sessionUUID, lastMeasurementTime: nil)
        }
    }
    
    private func enqueueForSaving(measurements: SDCardMeasurementsRow, buffer streamsWithMeasurements: inout [SDStream: [Measurement]]) {
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .f), default: []].append(Measurement(time: measurements.date, value: measurements.f, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .rh), default: []].append(Measurement(time: measurements.date, value: measurements.rh, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm1), default: []].append(Measurement(time: measurements.date, value: measurements.pm1, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm2_5), default: []].append(Measurement(time: measurements.date, value: measurements.pm2_5, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm10), default: []].append(Measurement(time: measurements.date, value: measurements.pm10, location: CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)))
    }
    
    private func createMeasurementStream(for sensorName: MeasurementStreamSensorName, sensorPackageName: String) -> MeasurementStream {
        MeasurementStream(sensorName: sensorName, sensorPackageName: sensorPackageName)
    }
}

fileprivate struct SDSession: Hashable {
    let uuid: SessionUUID
    let lastMeasurementTime: Date?
}

fileprivate struct SDStream: Hashable {
    let sessionUUID: SessionUUID
    let name: MeasurementStreamSensorName
}
