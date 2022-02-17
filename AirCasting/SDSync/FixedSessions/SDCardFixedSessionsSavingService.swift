// Created by Lunar on 09/12/2021.
//

import Foundation
import Resolver

//TODO: Refactor this part
class SDCardFixedSessionsSavingService {
    @Injected private var apiService: UploadFixedSessionAPIService
    
    func processAndSync(csvSession: CSVStreamsWithMeasurements, deviceID: String, completion: @escaping (Bool) -> Void) {
        guard !csvSession.sessions.isEmpty else {
            completion(true)
            return
        }
        let uploadParams = getSyncParams(csvSession: csvSession, deviceID: deviceID)
        
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
    
    private func getSyncParams(csvSession: CSVStreamsWithMeasurements, deviceID: String) -> [UploadFixedSessionAPIService.UploadFixedMeasurementsParams] {
        csvSession.streamsWithMeasurements.compactMap { sdStream, measurements -> UploadFixedSessionAPIService.UploadFixedMeasurementsParams? in
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
