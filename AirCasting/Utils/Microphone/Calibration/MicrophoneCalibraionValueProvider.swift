// Created by Lunar on 16/08/2022.
//

import Foundation

protocol MicrophoneCalibraionValueProvider {
    var zeroLevelAdjustment: Double { get }
}

protocol MicrophoneCalibrationValueWritable {
    var zeroLevelAdjustment: Double { get set }
}

class UserDefaultsMicrophoneCalibraionValueProvider: MicrophoneCalibraionValueProvider, MicrophoneCalibrationValueWritable {
    private let key = "UserDefaultsMicrophoneCalibraionValueProvider.value"
    
    var zeroLevelAdjustment: Double {
        get {
            guard UserDefaults.standard.valueExists(forKey: key) else { return 0.0 }
            return UserDefaults.standard.double(forKey: key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
