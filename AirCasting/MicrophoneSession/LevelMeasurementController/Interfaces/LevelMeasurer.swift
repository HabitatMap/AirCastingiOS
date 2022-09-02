// Created by Lunar on 17/05/2022.
//

import Foundation

/// Interface for objects that provide continous level measurement (like microphone db levels)
protocol LevelMeasurer {
    /// Starts a measuring session
    /// - Parameter with: `TimeInterval` beteween taking measurements
    func startMeasuring(with: TimeInterval)
}
