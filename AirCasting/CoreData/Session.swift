// Created by Lunar on 30/04/2021.
//

import Foundation
import CoreLocation

public struct Session {
    let uuid: SessionUUID
    let type: SessionType
    let name: String?
    let deviceType: DeviceType?
    let location: CLLocationCoordinate2D?
    let startTime: Date?

    let contribute: Bool
    let deviceId: String?
    let endTime: Date?
    let followedAt: Date?
    let gotDeleted: Bool
    let isIndoor: Bool
    let tags: String?
    let urlLocation: String?
    let version: Int16
    let measurementStreams: [Any]?
    let status: SessionStatus?

    init(uuid: SessionUUID, type: SessionType, name: String?, deviceType: DeviceType?, location: CLLocationCoordinate2D?, startTime: Date?,
         contribute: Bool = true, deviceId: String? = nil, endTime: Date? = nil, followedAt: Date? = nil, gotDeleted: Bool = false, isIndoor: Bool = false, tags: String? = nil, urlLocation: String? = nil, version: Int16 = 0, measurementStreams: [Any]? = nil, status: SessionStatus? = nil) {
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
    }
}

public struct SessionUUID: Codable, RawRepresentable, Hashable, CustomStringConvertible {
    public let rawValue: String

    public init() {
        rawValue = UUID().uuidString
    }

    public init?(uuidString: String) {
        if UUID(uuidString: uuidString) == nil {
            return nil
        }
        rawValue = uuidString
    }

    public init?(rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String {
        rawValue
    }
}

public enum SessionType: RawRepresentable, CustomStringConvertible, Hashable, Codable {
    case mobile
    case fixed
    case unknown(String)

    public init(from decoder: Decoder) throws {
        let singleValue = try decoder.singleValueContainer()
        let rawValue = try singleValue.decode(String.self)
        self.init(rawValue: rawValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var rawValue: String {
        switch self {
        case .mobile: return "MobileSession"
        case .fixed: return "FixedSession"
        case .unknown(let rawValue): return rawValue
        }
    }

    public init(rawValue: String) {
        switch rawValue {
        case "MobileSession": self = .mobile
        case "FixedSession": self = .fixed
        default: self = .unknown(rawValue)
        }
    }

    public var description: String {
        switch self {
        case .mobile: return NSLocalizedString("Mobile", comment: "Mobile session readable localized description")
        case .fixed: return NSLocalizedString("Fixed", comment: "Fixed session readable localized description")
        case .unknown: return NSLocalizedString("Other", comment: "Unknown session readable localized description")
        }
    }
}

public enum SessionStatus: Int {
    case NEW = -1
    case RECORDING = 0
    case FINISHED = 1
    case DISCONNETCED = 2
}

enum StreamingMethod: Int {
    case CELLULAR = 0
    case WIFI = 1
}

public enum DeviceType: Int, CustomStringConvertible {
    case MIC = 0
    case AIRBEAM3 = 1

    public var description: String {
        switch self {
        case .MIC: return "Device's Microphone"
        case .AIRBEAM3: return "AirBeam 3"
        }
    }
}
