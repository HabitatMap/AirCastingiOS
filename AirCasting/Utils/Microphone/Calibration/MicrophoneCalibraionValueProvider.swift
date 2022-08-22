// Created by Lunar on 16/08/2022.
//

import Foundation

enum MicrophoneCalibrationConstants {
    static let defaultValue = 90.0
    static let automaticCalibrationPadding = 30.0
}

/// Represents an object that can read dB level adjustment value
protocol MicrophoneCalibraionValueProvider {
    /// The value by which all `Microphone` measurements will be adjusted (by subtraction)
    var zeroLevelAdjustment: Double { get }
}

/// Represents an object that can write a new dB level adjustment value
protocol MicrophoneCalibrationValueWritable {
    /// The value by which all `Microphone` measurements will be adjusted (by subtraction)
    var zeroLevelAdjustment: Double { get set }
}

class UserDefaultsMicrophoneCalibraionValueProvider: MicrophoneCalibraionValueProvider, MicrophoneCalibrationValueWritable {
    private let key = "UserDefaultsMicrophoneCalibraionValueProvider.value"
    
    var zeroLevelAdjustment: Double {
        get {
            guard UserDefaults.standard.valueExists(forKey: key) else { return MicrophoneCalibrationConstants.defaultValue }
            return UserDefaults.standard.double(forKey: key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
