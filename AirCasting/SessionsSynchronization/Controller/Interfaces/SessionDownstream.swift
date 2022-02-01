// Created by Lunar on 16/06/2021.
//

import Foundation
import Combine

/// Defines interface for objects which provide downstream connection for sessions
///
/// Overview of the sync process:
/// 1. Fetch sessions stored on a device
/// 2. Diff them against upstream database
/// 3. Download/Upload/Delete accordingly (this interface)
protocol SessionDownstream {
    func download(session: SessionUUID) -> AnyPublisher<SessionsSynchronization.SessionDownstreamData, Error>
}

// MARK: Data structures

extension SessionsSynchronization {
    struct SessionDownstreamData: Equatable, Decodable {
        let id: Int
        let createdAt: Date
        let updatedAt: Date
        let userId: Int
        let urlToken: String
        let type: String
        let uuid: SessionUUID
        let title: String
        let tagList: String
        let startTime: Date
        let endTime: Date?
        let latitude: Double?
        let longitude: Double?
        let contribute: Bool
        let version: Int
        let streams: [String: MeasurementStreamDownstreamData]
        let location: URL?
        let isIndoor: Bool
        let notes: [NoteDownstreamData]
    }

    struct MeasurementStreamDownstreamData: Equatable, Codable {
        let id: MeasurementStreamID
        let sensorName: SensorName
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
        let size: Int
        let measurements: [MeasurementData]?
    }
    
    struct MeasurementData: Equatable, Codable {
        let value: Double
        let latitude: Double?
        let longitude: Double?
        let time: Date
    }
    
    struct NoteDownstreamData: Equatable, Codable {
        let date: Date
        let text: String
        let latitude: Double
        let longitude: Double
        let number: Int
    }
}
