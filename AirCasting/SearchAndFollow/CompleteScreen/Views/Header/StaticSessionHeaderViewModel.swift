// Created by Lunar on 04/03/2022.
//

import Foundation

class StaticSessionHeaderViewModel: ObservableObject {
    let sessionName: String
    let sessionStartTime: Date
    let sessionEndTime: Date
    let sensorType: String
    
    init(name: String, startTime: Date, endTime: Date, sensorType: String) {
        sessionName = name
        sessionStartTime = startTime
        sessionEndTime = endTime
        self.sensorType = sensorType
    }
}
