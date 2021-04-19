//
//  Session+CoreDataClass.swift
//  AirCasting
//
//  Created by Lunar on 01/04/2021.
//

import Foundation
import CoreData

public typealias SessionUUID = UUID

@objc(Session)
public class Session: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Session> {
        return NSFetchRequest<Session>(entityName: "Session")
    }

    @NSManaged public var contribute: Bool
    @NSManaged public var deviceId: String?

    @NSManaged public var endTime: Date?
    @NSManaged public var followedAt: Date?
    @NSManaged public var gotDeleted: Bool
    @NSManaged public var isIndoor: Bool
    @NSManaged public var latitude: Double
    @NSManaged public var locationless: Bool
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var tags: String?

    @NSManaged public var urlLocation: String?
    @NSManaged public var version: Int16
    @NSManaged public var id: Int64
    @NSManaged public var measurementStreams: NSSet?

    public var status: SessionStatus? {
        get { (value(forKey: "status") as? Int).flatMap(SessionStatus.init(rawValue:)) }
        set { setValue(newValue?.rawValue, forKey: "status") }
    }

    public var uuid: SessionUUID! {
        get { (value(forKey: "uuid") as? String).flatMap(SessionUUID.init(uuidString:)) }
        set { setValue(newValue?.uuidString, forKey: "uuid") }
    }

    public var deviceType: DeviceType? {
        get { (value(forKey: "deviceType") as? Int).flatMap(DeviceType.init(rawValue:)) }
        set { setValue(newValue?.rawValue, forKey: "deviceType") }
    }

    public var type: SessionType! {
        get { SessionType(rawValue: value(forKey: "type") as! Int16) }
        set { setValue(newValue?.rawValue, forKey: "type") }
    }
}

extension SessionType {
    @available(*, deprecated, message: "Only temporary for database. Database underling storage change needed")
    fileprivate var rawValue: Int16 {
        switch self {
        case .MOBILE: return 0
        case .FIXED: return 1
        case .unknown: return -1
        }
    }
    @available(*, deprecated, message: "Only temporary for database. Database underling storage change needed")
    fileprivate init(rawValue: Int16) {
        switch rawValue {
        case 0: self = .MOBILE
        case 1: self = .FIXED
        default: self = .unknown("")
        }
    }
}
// MARK: Generated accessors for measurementStreams
extension Session {

    @objc(addMeasurementStreamsObject:)
    @NSManaged public func addToMeasurementStreams(_ value: MeasurementStream)

    @objc(removeMeasurementStreamsObject:)
    @NSManaged public func removeFromMeasurementStreams(_ value: MeasurementStream)

    @objc(addMeasurementStreams:)
    @NSManaged public func addToMeasurementStreams(_ values: NSSet)

    @objc(removeMeasurementStreams:)
    @NSManaged public func removeFromMeasurementStreams(_ values: NSSet)

}
