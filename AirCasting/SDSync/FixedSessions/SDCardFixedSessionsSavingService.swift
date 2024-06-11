// Created by Lunar on 09/12/2021.
//

import Foundation
import CoreLocation
import Resolver

enum UploadingError: Error {
    case uploadError
    case readingFileError
}

class SDCardFixedSessionsUploadingService {
    @Injected private var fileLineReader: FileLineReader
    @Injected private var sessionStorage: SessionStorage
    @Injected private var apiService: UploadFixedSessionAPIService
    private let bufferThreshold = 50
    
    func processAndUpload(filesDirectoryURL: URL, deviceID: String, completion: @escaping (Result<[SessionUUID], Error>) -> Void) {
        DispatchQueue.global().async {
            var sessionsForUpload = Set<SessionUUID>()
            var streamsWithMeasurements: [SDStream: [Measurement]] = [:]
            
            // We don't want to upload sessions of other users
            var sessionsToIgnore: [SessionUUID] = []
            var uploadFailed = false
            
            var readLines = 0
            do {
                try self.provideMeasurements(of: filesDirectoryURL, deviceID: deviceID) { measurements in
                    guard !uploadFailed else { return }
                    readLines += 1
                    
                    guard !sessionsToIgnore.contains(measurements.sessionUUID),
                          self.checkIfSessionExistis(sessionUUID: measurements.sessionUUID, sessionsToIgnore: &sessionsToIgnore)
                    else { return }
                    
                    sessionsForUpload.insert(measurements.sessionUUID)
                    
                    Log.info("Enqueueing session: \(measurements.sessionUUID)")
                    self.enqueueForUploading(measurements: measurements, buffer: &streamsWithMeasurements, deviceID: deviceID)
                    
                    guard readLines == self.bufferThreshold else { return }
                    
                    guard self.processAndSync(streamsWithMeasurements: streamsWithMeasurements, deviceID: deviceID) else {
                        Log.error("Upload fixed sessions stream failed")
                        uploadFailed = true
                        return
                    }
                    streamsWithMeasurements = [:]
                    readLines = 0
                }
                
                guard !uploadFailed else {
                    completion(.failure(UploadingError.uploadError))
                    return
                }
                
                guard self.processAndSync(streamsWithMeasurements: streamsWithMeasurements, deviceID: deviceID) else {
                    completion(.failure(UploadingError.uploadError))
                    return
                }
                
                completion(.success(Array(sessionsForUpload)))
            } catch {
                completion(.failure(UploadingError.readingFileError))
            }
        }
    }
    
    private func provideMeasurements(of url: URL, deviceID: String, progress: (SDCardMeasurementsRow) -> Void) throws {
        let parser = Resolver.resolve(SDMeasurementsParser.self, args: deviceID)
        
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return
        }
        
        guard isDirectory.boolValue else {
            try parser.enumerateMeasurements(url: url, action: progress)
            return
        }
        
        let files = try FileManager.default.contentsOfDirectory(atPath: url.path).compactMap({ url.path + "/" + $0 }).compactMap(URL.init(string:))
        Log.info("Reading all file lines from directory at \(url.path). Files count: \(files.count)")
        try files.forEach { file in
            Log.info("Reading file: \(file)")
            try parser.enumerateMeasurements(url: file, action: progress)
        }
    }
    
    private func enqueueForUploading(measurements: SDCardMeasurementsRow, buffer streamsWithMeasurements: inout [SDStream: [Measurement]], deviceID: String) {
        var location: CLLocationCoordinate2D?
        if let lat = measurements.lat, let long = measurements.long {
            location = CLLocationCoordinate2D(latitude: lat, longitude: long)
        }
        
        let date = measurements.date
        
        if deviceID.starts(with: "AirBeamMini") {
            streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .mini_pm1, header: .pm1), default: []]
                .append(Measurement(time: date, value: measurements.pm1, location: location))
            streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .mini_pm2_5, header: .pm2_5), default: []]
                .append(Measurement(time: date, value: measurements.pm2_5, location: location))
        } else {
            if let f = measurements.f {
                streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .ab3_f, header: .f), default: []]
                    .append(Measurement(time: date, value: f, location: location))
            }
            if let rh = measurements.rh {
                streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .ab3_rh, header: .rh), default: []]
                    .append(Measurement(time: date, value: rh, location: location))
            }
            streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .ab3_pm1, header: .pm1), default: []]
                .append(Measurement(time: date, value: measurements.pm1, location: location))
            streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .ab3_pm2_5, header: .pm2_5), default: []]
                .append(Measurement(time: date, value: measurements.pm2_5, location: location))
            if let pm10 = measurements.pm10 {
                streamsWithMeasurements[SDStream(sessionUUID: measurements.sessionUUID, deviceID: deviceID, name: .ab3_pm10, header: .pm10), default: []]
                    .append(Measurement(time: date, value: pm10, location: location))
            }
        }
    }
    
    private func checkIfSessionExistis(sessionUUID: SessionUUID, sessionsToIgnore: inout [SessionUUID]) -> Bool {
        var doesSessionExist = false
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        sessionStorage.accessStorage { storage in
            doesSessionExist = (try? storage.getExistingSession(with: sessionUUID)) != nil
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        doesSessionExist ? nil : sessionsToIgnore.append(sessionUUID)
        return doesSessionExist
    }
    
    private func processAndSync(streamsWithMeasurements: [SDStream: [Measurement]], deviceID: String) -> Bool {
        assert(!Thread.isMainThread)
        Log.info("Starting streams upload")
        let uploadParams = getSyncParams(streamsWithMeasurements: streamsWithMeasurements, deviceID: deviceID)
        var allSuccess = true
        
        guard !uploadParams.isEmpty else {
            return true
        }
        
        let dispatchGroup = DispatchGroup()
        uploadParams.forEach { params in
            dispatchGroup.enter()
            apiService.uploadFixedSession(input: params) { result in
                switch result {
                case .success:
                    Log.info("[SD Sync] Stream uploadedd. Session: \(params.session_uuid) Sensor: \(params.sensor_name ?? "")")
                case .failure(let error):
                    allSuccess = false
                    Log.error("[SD Sync] Stream syncing failed: \(error)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.wait()
        return allSuccess
    }
    
    private func getSyncParams(streamsWithMeasurements: [SDStream: [Measurement]], deviceID: String) -> [UploadFixedSessionAPIService.UploadFixedMeasurementsParams] {
        streamsWithMeasurements.compactMap { sdStream, measurements -> UploadFixedSessionAPIService.UploadFixedMeasurementsParams? in
            var stream: CSVMeasurementStream?
            
            if deviceID.starts(with: "AirBeamMini") {
                stream = CSVMeasurementStream.MINI_SUPPORTED_STREAMS[sdStream.header]
            } else {
                stream = CSVMeasurementStream.SUPPORTED_STREAMS[sdStream.header]
            }
            
            guard let stream = stream else {
                Log.info("Unsupported stream")
                return nil
            }
            
            let milisecondsInSecond = 1000
            let csvMeasurements = measurements.map {
                CSVMeasurement(longitude: $0.location?.longitude ?? 200,
                               latitude: $0.location?.latitude ?? 200,
                               milliseconds: abs(Int($0.time.timeIntervalSince1970.remainder(dividingBy: TimeInterval(milisecondsInSecond)))),
                               time: $0.time,
                               value: $0.value)
            }
            
            return UploadFixedSessionAPIService.UploadFixedMeasurementsParams(session_uuid: sdStream.sessionUUID.rawValue,
                                                                              sensor_package_name: deviceID,
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
