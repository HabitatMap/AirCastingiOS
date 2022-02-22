// Created by Lunar on 22/02/2022.
//

import Foundation

struct SearchSession {
    let name: String
    let startTime: Date
    let endTime: Date
    let type: SessionType
    let longitude: Double
    let latitude: Double
    let streams: [SearchSessionStream]
    
    struct SearchSessionStream: Identifiable {
        var id: Int
        let sensorPackageName: String?
        let sensorName: String
        let measurements: [SearchSessionMeasurement]
        var isTemperature: Bool { sensorName == Constants.MeasurementType.temperature }
        
    }
    
    struct SearchSessionMeasurement {
        let time: Date
        let value: Double
    }
    
    public var sortedStreams: [SearchSessionStream]? {
        // To implement
        return streams
    }
    
    #if DEBUG
    
    static var mock: SearchSession {
        let session =  self.init(name: "Mock Session", startTime: DateBuilder.getFakeUTCDate() - 60, endTime: DateBuilder.getFakeUTCDate(), type: .mobile, longitude: 50.0, latitude: 50.0, streams: [.init(id: 1, sensorPackageName: "AirBeam3", sensorName: Constants.MeasurementType.temperature, measurements: [.init(time: DateBuilder.getFakeUTCDate(), value: 20)])])
        // ...
                
        return session
    }
    #endif
}
