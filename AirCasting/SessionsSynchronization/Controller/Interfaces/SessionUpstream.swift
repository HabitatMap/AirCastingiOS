// Created by Lunar on 16/06/2021.
//

import Foundation
import Combine

/// Defines interface for objects which provide upstream connection for sessions
///
/// Overview of the sync process:
/// 1. Fetch sessions stored on a device
/// 2. Diff them against upstream database
/// 3. Download/Upload/Delete accordingly (this interface)
protocol SessionUpstream {
    func upload(session: SessionsSynchronization.SessionUpstreamData) -> Future<Void, Error>
}

// MARK: Data structures

extension SessionsSynchronization {
    struct SessionUpstreamData: Equatable, Encodable {
        typealias SensorName = String
        let uuid: SessionUUID
        let type: String
        let title: String
        let tagList: String
        let startTime: Date
        let endTime: Date?
        let contribute: Bool
        let isIndoor: Bool
        let version: Int?
        let streams: [SensorName: MeasurementStreamUpstreamData]
        let latitude: Double?
        let longitude: Double?
        let deleted: Bool
    }
    
    struct MeasurementStreamUpstreamData: Equatable, Codable {
        let id: MeasurementStreamID
        let sensorName: String
        let sensorPackageName: String
        let unitName: String
        let measurementType: String
        let measurementShortType: String
        let unitSymbol: String
        let thresholdVeryLow: Int
        let thresholdLow: Int
        let thresholdMedium: Int
        let thresholdHigh: Int
        let thresholdVeryHigh: Int
        let deleted: Bool
    }
}
