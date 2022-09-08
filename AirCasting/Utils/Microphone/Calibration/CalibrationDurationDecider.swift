// Created by Lunar on 16/08/2022.
//

import Foundation

protocol CalibrationDurationDecider {
    func shouldCalibrationFinish(calibrationStartDate: Date, desiredDuration: Double) -> Bool
}

class DefaultCalibrationDurationDecider: CalibrationDurationDecider {
    func shouldCalibrationFinish(calibrationStartDate: Date, desiredDuration: Double) -> Bool {
        abs(calibrationStartDate.timeIntervalSinceNow) > desiredDuration
    }
}
