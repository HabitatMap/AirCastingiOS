// Created by Lunar on 22/11/2021.
//

import Foundation

protocol StreamRemover {
    func deleteStreams(session: SessionEntity, completion: @escaping () -> Void)
}

class StreamRemoverDefault: StreamRemover {

    private let authorization: RequestAuthorisationService
    private let urlProvider: BaseURLProvider
    
    init(authorization: RequestAuthorisationService, urlProvider: BaseURLProvider) {
        self.authorization = authorization
        self.urlProvider = urlProvider
    }
    
    private struct APICallData: Encodable {
        let data: String
    }

    func deleteStreams(session: SessionEntity, completion: @escaping () -> Void) {
        let url = urlProvider.baseAppURL.appendingPathComponent("api/user/sessions/update_session.json")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var data = [String : CreateSessionApi.MeasurementStreamParams]()
        
        session.allStreams?.forEach({ stream in
            data[stream.sensorName!] = CreateSessionApi.MeasurementStreamParams(deleted: stream.gotDeleted,
                                                                                sensor_package_name: stream.sensorPackageName!,
                                                                                sensor_name: stream.sensorName,
                                                                                measurement_type: stream.measurementType,
                                                                                measurement_short_type: stream.measurementShortType,
                                                                                unit_name: stream.unitName ?? "",
                                                                                unit_symbol: stream.unitSymbol,
                                                                                threshold_very_high: Int(stream.thresholdVeryHigh),
                                                                                threshold_high: Int(stream.thresholdHigh),
                                                                                threshold_medium: Int(stream.thresholdMedium),
                                                                                threshold_low: Int(stream.thresholdLow),
                                                                                threshold_very_low: Int(stream.thresholdVeryLow),
                                                                                measurements: [])
        })
        
        let sessionToPass = CreateSessionApi.SessionParams(uuid: session.uuid,
                                                 type: session.type,
                                                 title: session.name!,
                                                 tag_list: session.tags!,
                                                 start_time: session.startTime!,
                                                 end_time: session.endTime!,
                                                 contribute: session.contribute,
                                                 is_indoor: session.isIndoor,
                                                 notes: [],
                                                 version: Int(session.version),
                                                 streams: data,
                                                 latitude: session.location?.latitude,
                                                 longitude: session.location?.longitude)
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(sessionToPass)
            guard let jsonString = String(data: encodedData, encoding: .utf8) else {
                throw BodyEncodingError.dataCannotBeStringified(data: encodedData)
            }
            
            request.httpBody = try encoder.encode(APICallData(data: jsonString))
            try authorization.authorise(request: &request)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else { return }
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    completion()
                }
            }
            task.resume()
        } catch {
            Log.info("Error when trying to delete from database")
        }
    }
}

class StreamRemoverDefaultDummy: StreamRemover {
    func deleteStreams(session: SessionEntity, completion: @escaping () -> Void) {
        print("deletingStreams")
    }
}
