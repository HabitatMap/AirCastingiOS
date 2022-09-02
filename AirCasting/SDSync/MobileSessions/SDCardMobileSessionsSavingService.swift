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
        var streamsWithMeasurements: [SDStream: [Measurement]] = [:]

        do {
            try self.fileLineReader.readLines(of: fileURL, progress: { line in
                switch line {
                case .line(let content):
                    let measurementsRow = self.parser.parseMeasurement(lineString: content)
                    guard let measurements = measurementsRow else { return }
                    shouldSessionBeIgnored(sessionUUID: measurements.sessionUUID, deviceID: deviceID) { value in
                        guard !value else { return }
                        self.getProcessedSession(sessionUUID: measurements.sessionUUID) { session in

                            if session == nil {
                                self.processSession(sessionUUID: measurements.sessionUUID, deviceID: deviceID, completion: { session in
                                    guard let createdSession = session else { return }
                                    if createdSession.lastMeasurementTime == nil {
                                        streamsWithMeasurements.keys.forEach { stream in
                                            self.createSession(sdStream: stream,
                                                               location: .init(latitude: measurements.lat, longitude: measurements.long),
                                                               time: measurements.date)
                                        }
                                    }
                                })
                            }
                            guard session!.lastMeasurementTime == nil || measurements.date > session!.lastMeasurementTime! else { return }
                        }
                    }
                    // TODO: this causes a lot of memory usage:
                    self.enqueueForSaving(measurements: measurements, buffer: &streamsWithMeasurements)

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
                Log.error("Saving measurements failed: \(error)")
            }
        }
    }

    private func shouldSessionBeIgnored(sessionUUID: SessionUUID, deviceID: String, completion: @escaping ((Bool) -> Void)) {
        getExistingSession(sessionUUID: sessionUUID) { session in
            if let session = session, !session.isInStandaloneMode, session.sensorPackageName != deviceID {
                Log.info("[SD SYNC] Ignoring session \(session.name ?? "none")")
                completion(true)
            }
            completion(false)
        }
    }

    private func getProcessedSession(sessionUUID: SessionUUID, completion: @escaping ((SDSession?) -> Void)) {
        getExistingSession(sessionUUID: sessionUUID) { session in
            guard let uuid = session?.uuid else { completion(nil); return }
            completion(SDSession(uuid: uuid, lastMeasurementTime: session?.lastMeasurementTime))
        }
    }

    private func processSession(sessionUUID: SessionUUID, deviceID: String, completion: @escaping ((SDSession?) -> Void)) {
        getExistingSession(sessionUUID: sessionUUID) { session in
            if let existingSession = session {
                guard existingSession.isInStandaloneMode && existingSession.sensorPackageName == deviceID else {
                    completion(nil)
                    return
                }
                completion(SDSession(uuid: sessionUUID, lastMeasurementTime: existingSession.lastMeasurementTime))
            } else {
                completion(SDSession(uuid: sessionUUID, lastMeasurementTime: nil))
            }
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

    private func getExistingSession(sessionUUID: SessionUUID, completion: @escaping ((SessionEntity?) -> Void)) {
        measurementStreamStorage.accessStorage { storage in
            let session = try? storage.getExistingSession(with: sessionUUID)
            completion(session)
        }
    }
}
