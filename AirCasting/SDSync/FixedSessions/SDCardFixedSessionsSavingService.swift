// Created by Lunar on 09/12/2021.
//

import Foundation

class SDCardFixedSessionsSavingService {
    
    let apiService: UploadFixedSessionAPIService
    
    init(apiService: UploadFixedSessionAPIService) {
        self.apiService = apiService
    }
    
    func processAndSync(csvSession: CSVSession, deviceID: String, completion: @escaping (Bool) -> Void) {
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
    
    private func getSyncParams(csvSession: CSVSession, deviceID: String) -> [UploadFixedSessionAPIService.UploadFixedMeasurementsParams] {
        let all = csvSession.sessions.map { session -> [UploadFixedSessionAPIService.UploadFixedMeasurementsParams] in
            let sessionStreams = csvSession.streamsWithMeasurements.filter { $0.key.sessionUUID == session.uuid }
            
            let perStreamParams = sessionStreams.map { sdStream, measurements -> UploadFixedSessionAPIService.UploadFixedMeasurementsParams in
                let stream = CSVMeasurementStream.SUPPORTED_STREAMS[sdStream.header]!
                let MILLISECONDS_IN_SECOND = 1000
                let csvMeasurements = measurements.map {
                    CSVMeasurement(longitude: $0.location?.longitude,
                                   latitude: $0.location?.latitude,
                                   milliseconds: abs(Int($0.time.timeIntervalSince1970.remainder(dividingBy: TimeInterval(MILLISECONDS_IN_SECOND)))),
                                   time: $0.time,
                                   value: $0.value)
                }
                return UploadFixedSessionAPIService.UploadFixedMeasurementsParams(session_uuid: session.uuid.rawValue,
                                                                                  sensor_package_name: stream.sensorPackageName(deviceId: deviceID),
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
            Log.info("[SD Sync] Syncing \(perStreamParams.count) streams for session \(session.uuid)")
            return perStreamParams
        }
        .flatMap { $0 }
        
        return all
    }
    
}
