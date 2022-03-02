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
        
    }
    
    struct SearchSessionMeasurement {
        let time: Date
        let value: Double
    }
    
    
//    #if DEBUG
    static var mock: SearchSession {
        let session =  self.init(name: "Mock Session",
                                 startTime: DateBuilder.getFakeUTCDate() - 60,
                                 endTime: DateBuilder.getFakeUTCDate(),
                                 type: .mobile,
                                 longitude: 19.944544,
                                 latitude: 50.049683,
                                 streams: [
                                    .init(id: 1, sensorPackageName: "AirBeam3", sensorName: "AirBeam3:PM10", measurements: [.init(time: DateBuilder.getFakeUTCDate(), value: 20), .init(time: DateBuilder.getFakeUTCDate(), value: 1), .init(time: DateBuilder.getFakeUTCDate(), value: 35)]),
                                    .init(id: 2, sensorPackageName: "AirBeam3", sensorName: "AirBeam3:PM1", measurements: [.init(time: DateBuilder.getFakeUTCDate(), value: 20), .init(time: DateBuilder.getFakeUTCDate(), value: 1), .init(time: DateBuilder.getFakeUTCDate(), value: 15)]),
                                    .init(id: 3, sensorPackageName: "AirBeam3", sensorName: "AirBeam3-PM2.5", measurements: [.init(time: DateBuilder.getFakeUTCDate(), value: 20), .init(time: DateBuilder.getFakeUTCDate(), value: 1), .init(time: DateBuilder.getFakeUTCDate(), value: 1)]),
                                    .init(id: 4, sensorPackageName: "AirBeam3", sensorName: "AirBeam3-F", measurements: [.init(time: DateBuilder.getFakeUTCDate(), value: 20), .init(time: DateBuilder.getFakeUTCDate(), value: 1), .init(time: DateBuilder.getFakeUTCDate(), value: 12)]),
                                    .init(id: 5, sensorPackageName: "AirBeam3", sensorName: "AirBeam3-RH", measurements: [.init(time: DateBuilder.getFakeUTCDate(), value: 20), .init(time: DateBuilder.getFakeUTCDate(), value: 1), .init(time: DateBuilder.getFakeUTCDate(), value: 50)])
                                 ])
        // ...
                
        return session
    }
//    #endif
}
