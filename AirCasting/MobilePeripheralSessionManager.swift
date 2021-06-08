// Created by Lunar on 07/06/2021.
//

import Foundation

class MobilePeripheralSessionManager {
    private let measurementStreamStorage: MeasurementStreamStorage
    
    var activeMobileSessions: [MobileSession] = []
    
    init(measurementStreamStorage: MeasurementStreamStorage) {
        self.measurementStreamStorage = measurementStreamStorage
    }
}
