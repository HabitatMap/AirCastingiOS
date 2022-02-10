// Created by Lunar on 09/12/2021.
//

import Foundation
import CoreLocation
import Resolver

class SDCardFixedSessionsUploadingService {
    @Injected private var fileLineReader: FileLineReader
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    @Injected private var apiService: UploadFixedSessionAPIService
    private let parser = SDCardMeasurementsParser()
    
    private let bufferThreshold = 200
    
    func processAndUpload(fileURL: URL, deviceID: String, completion: @escaping (Result<[SessionUUID], Error>) -> Void) {
        var processedSessions = Set<SessionUUID>()
        var streamsWithMeasurements: [SDStream: [Measurement]] = [:]
        
        // We don't want to upload sessions of other users
        var sessionsToIgnore: [SessionUUID] = []
        
        var readLines = 0
        
        measurementStreamStorage.accessStorage { storage in
            do {
                try self.fileLineReader.readLines(of: fileURL, progress: { line in
                    switch line {
                    case .line(let content):
                        readLines += 1
                        Log.info("LINE: \(content)")
                        let measurementsRow = self.parser.parseMeasurement(lineString: content)
                        guard let measurements = measurementsRow, !sessionsToIgnore.contains(measurements.sessionUUID) else { return }
                        
                        let session = processedSessions.first(where: { $0 == measurements.sessionUUID })
                        if session == nil {
                            guard self.checkIfSessionExistis(storage: storage, sessionUUID: measurements.sessionUUID, sessionsToIgnore: &sessionsToIgnore) else { return }
                            processedSessions.insert(measurements.sessionUUID)
                            Log.info("Processed session: \(measurements.sessionUUID)")
                        }
                        
                        Log.info("Enqueueing session: \(measurements.sessionUUID)")
                        self.enqueueForUploading(measurements: measurements, buffer: &streamsWithMeasurements)
                        
                        if readLines == self.bufferThreshold {
                            self.processAndSync(streamsWithMeasurements: streamsWithMeasurements, deviceID: deviceID) { result in Log.info("Processed \(readLines) lines: \(result)") }
                            streamsWithMeasurements = [:]
                            readLines = 0
                        }
                    case .endOfFile:
                        Log.info("Reached end of csv file")
                    }
                })
                if readLines != 0 {
                    self.processAndSync(streamsWithMeasurements: streamsWithMeasurements, deviceID: deviceID) { result in Log.info("Processed \(readLines) lines: \(result)") }
                }
                
                completion(.success(Array(processedSessions)))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func enqueueForUploading(measurements: SDCardMeasurementsRow, buffer streamsWithMeasurements: inout [SDStream: [Measurement]]) {
        let location = CLLocationCoordinate2D(latitude: measurements.lat, longitude: measurements.long)
        let date = measurements.date
        
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .f, header: .f), default: []]
            .append(Measurement(time: date, value: measurements.f, location: location))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .rh, header: .rh), default: []]
            .append(Measurement(time: date, value: measurements.rh, location: location))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm1, header: .pm1), default: []]
            .append(Measurement(time: date, value: measurements.pm1, location: location))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm2_5, header: .pm2_5), default: []]
            .append(Measurement(time: date, value: measurements.pm2_5, location: location))
        streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, name: .pm10, header: .pm10), default: []]
            .append(Measurement(time: date, value: measurements.pm10, location: location))
    }
    
    private func checkIfSessionExistis(storage: HiddenCoreDataMeasurementStreamStorage, sessionUUID: SessionUUID, sessionsToIgnore: inout [SessionUUID]) -> Bool {
        if (try? storage.getExistingSession(with: sessionUUID)) != nil {
            return true
        } else {
            sessionsToIgnore.append(sessionUUID)
            return false
        }
    }
    
    func processAndSync(streamsWithMeasurements: [SDStream: [Measurement]], deviceID: String, completion: @escaping (Bool) -> Void) {
        let uploadParams = getSyncParams(streamsWithMeasurements: streamsWithMeasurements, deviceID: deviceID)
        var tasksCompleted = 0
        var allSuccess = true
        
        uploadParams.forEach { params in
            apiService.uploadFixedSession(input: params) { result in
                tasksCompleted += 1
                
                switch result {
                case .success:
                    Log.info("[SD Sync] Stream uploadedd. Session: \(params.session_uuid) Sensor: \(params.sensor_name ?? "")")
                case .failure(let error):
                    allSuccess = false
                    Log.error("[SD Sync] Stream syncing failed: \(error)")
                }
                
                if tasksCompleted >= uploadParams.count {
                    completion(allSuccess)
                }
            }
        }
    }
    
    private func getSyncParams(streamsWithMeasurements: [SDStream: [Measurement]], deviceID: String) -> [UploadFixedSessionAPIService.UploadFixedMeasurementsParams] {
        streamsWithMeasurements.compactMap { sdStream, measurements -> UploadFixedSessionAPIService.UploadFixedMeasurementsParams? in
            guard let stream = CSVMeasurementStream.SUPPORTED_STREAMS[sdStream.header] else {
                Log.info("Unsupported stream")
                return nil
            }
            let milisecondsInSecond = 1000
            let csvMeasurements = measurements.map {
                CSVMeasurement(longitude: $0.location?.longitude,
                               latitude: $0.location?.latitude,
                               milliseconds: abs(Int($0.time.timeIntervalSince1970.remainder(dividingBy: TimeInterval(milisecondsInSecond)))),
                               time: $0.time,
                               value: $0.value)
            }
            
            return UploadFixedSessionAPIService.UploadFixedMeasurementsParams(session_uuid: sdStream.sessionUUID.rawValue,
                                                                              sensor_package_name: deviceID.replacingOccurrences(of: ":", with: "-"),
                                                                              sensor_name: stream.sensorName,
                                                                              measurement_type: stream.measurementType,
                                                                              measurement_short_type: stream.measurementShortType,
                                                                              unit_name: stream.unitName,
                                                                              unit_symbol: stream.unitSymbol,
                                                                              threshold_very_high: stream.thresholdVeryHigh,
                                                                              threshold_high: stream.thresholdHigh,
                                                                              threshold_medium: stream.thresholdMedium,
                                                                              threshold_low: stream.thresholdLow,
                                                                              threshold_very_low: stream.thresholdVeryLow,
                                                                              measurements: csvMeasurements)
        }
    }
    
}
