//
//  Session+CoreDataClass.swift
//  AirCasting
//
//  Created by Lunar on 01/04/2021.
//

import Foundation
import CoreData
import struct CoreLocation.CLLocationCoordinate2D

public struct SessionEntityLocalID {
    let id: NSManagedObjectID
}

@objc(SessionEntity)
public class SessionEntity: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SessionEntity> {
        return NSFetchRequest<SessionEntity>(entityName: "SessionEntity")
    }

    @NSManaged public var contribute: Bool
    @NSManaged public var deviceId: String?

    @NSManaged public var endTime: Date?
    @NSManaged public var followedAt: Date?
    @NSManaged public var gotDeleted: Bool
    @NSManaged public var isIndoor: Bool

    @NSManaged public var locationless: Bool

    @NSManaged public var name: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var tags: String?

    @NSManaged public var urlLocation: String?
    @NSManaged public var version: Int16
    
    /// Of type MeasurementStreamEntity
    @NSManaged public var measurementStreams: NSOrderedSet?

    public var localID: SessionEntityLocalID {
        SessionEntityLocalID(id: objectID)
    }

    public var location: CLLocationCoordinate2D? {
        get {
            guard let lat = value(forKey: "latitude") as? CLLocationDegrees,
                    let lon = value(forKey: "longitude") as? CLLocationDegrees else {
                return nil
            }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        set {
            setValue(newValue?.latitude, forKey: "latitude")
            setValue(newValue?.longitude, forKey: "longitude")
        }
    }

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
    
    public var allStreams: [MeasurementStreamEntity]? {
        measurementStreams?.array as? [MeasurementStreamEntity]
    }
    
    func streamWith(sensorName: String) -> MeasurementStreamEntity? {
       allStreams?.first { stream in
            stream.sensorName == sensorName
        }
    }
    
}

extension NSFetchRequest where ResultType == SessionEntity {
    public func typePredicate(_ type: SessionType) -> NSPredicate {
        NSPredicate(format: "type == \"\(type.rawValue)\"")
    }
}
// MARK: Generated accessors for measurementStreams
extension SessionEntity {

    @objc(addMeasurementStreamsObject:)
    @NSManaged public func addToMeasurementStreams(_ value: MeasurementStreamEntity)

    @objc(removeMeasurementStreamsObject:)
    @NSManaged public func removeFromMeasurementStreams(_ value: MeasurementStreamEntity)

    @objc(addMeasurementStreams:)
    @NSManaged public func addToMeasurementStreams(_ values: NSSet)

    @objc(removeMeasurementStreams:)
    @NSManaged public func removeFromMeasurementStreams(_ values: NSSet)

}
