//
//  Session+CoreDataClass.swift
//  AirCasting
//
//  Created by Lunar on 01/04/2021.
//

import Foundation
import CoreData

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
    @NSManaged public var measurementStreams: NSSet?

    public var status: SessionStatus? {
        get { (value(forKey: "status") as? Int).flatMap(SessionStatus.init(rawValue:)) }
        set { setValue(newValue?.rawValue, forKey: "status") }
    }

    public var uuid: SessionUUID! {
        get { SessionUUID(rawValue: value(forKey: "uuid") as! String) }
        set { setValue(newValue.rawValue, forKey: "uuid") }
    }

    public var deviceType: DeviceType? {
        get { (value(forKey: "deviceType") as? Int).flatMap(DeviceType.init(rawValue:)) }
        set { setValue(newValue?.rawValue, forKey: "deviceType") }
    }

    public var type: SessionType! {
        get { SessionType(rawValue:(value(forKey: "type") as! String)) }
        set { setValue(newValue.rawValue, forKey: "type") }
    }
}

extension NSFetchRequest where ResultType == Session {
    public func typePredicate(_ type: SessionType) -> NSPredicate {
        NSPredicate(format: "type == \"\(type.rawValue)\"")
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
