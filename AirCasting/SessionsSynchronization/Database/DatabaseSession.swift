// Created by Lunar on 30/04/2021.
//

import Foundation
import CoreLocation

extension Database {
    public struct Session {
        public let uuid: SessionUUID
        public let type: SessionType
        public let name: String?
        public let deviceType: DeviceType?
        public let location: CLLocationCoordinate2D?
        public let startTime: Date?
        public let contribute: Bool
        public let deviceId: String?
        public let endTime: Date?
        public let followedAt: Date?
        public let gotDeleted: Bool
        public let isIndoor: Bool
        public let tags: String?
        public let urlLocation: String?
        public let version: Int?
        public let measurementStreams: [MeasurementStream]?
        public let status: SessionStatus?
        public let notes: [Note]?
        public let deviceUUID: DeviceUUID?

        public init(uuid: SessionUUID, type: SessionType, name: String?, deviceType: DeviceType?, location: CLLocationCoordinate2D?, startTime: Date?,
                    contribute: Bool = true, deviceId: String? = nil, endTime: Date? = nil, followedAt: Date? = nil, gotDeleted: Bool = false, isIndoor: Bool = false, tags: String? = nil, urlLocation: String? = nil, version: Int? = nil, measurementStreams: [MeasurementStream]? = nil, status: SessionStatus? = nil, notes: [Note]? = [], deviceUUID: DeviceUUID? = nil) {
            self.uuid = uuid
            self.type = type
            self.name = name
            self.deviceType = deviceType
            self.location = location
            self.startTime = startTime
            self.contribute = contribute
            self.deviceId = deviceId
            self.endTime = endTime
            self.followedAt = followedAt
            self.gotDeleted = gotDeleted
            self.isIndoor = isIndoor
            self.tags = tags
            self.urlLocation = urlLocation
            self.version = version
            self.measurementStreams = measurementStreams
            self.status = status
            self.notes = notes
            self.deviceUUID = deviceUUID
        }
    }
}
