//
//  Session+CoreDataProperties.swift
//  AirCasting
//
//  Created by Lunar on 01/04/2021.
//
//

import Foundation
import CoreData


extension Session {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Session> {
        return NSFetchRequest<Session>(entityName: "Session")
    }

    @NSManaged public var contribute: Bool
    @NSManaged public var deviceId: String?
    @NSManaged public var deviceType: Int16
    @NSManaged public var endTime: Date?
    @NSManaged public var followedAt: Date?
    @NSManaged public var gotDeleted: Bool
    @NSManaged public var isIndoor: Bool
    @NSManaged public var latitude: Double
    @NSManaged public var locationless: Bool
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var status: Int16
    @NSManaged public var tags: String?
    @NSManaged public var type: Int16
    @NSManaged public var urlLocation: String?
    #warning("TODO: change session.uuid type to UUID type")
    @NSManaged public var uuid: String?
    @NSManaged public var version: Int16
    @NSManaged public var id: Int64
    @NSManaged public var measurementStreams: NSSet?

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

extension Session : Identifiable {

}
