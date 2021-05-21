//
//  MeasurementStream+CoreDataClass.swift
//  AirCasting
//
//  Created by Lunar on 01/04/2021.
//
//

import Foundation
import CoreData

public typealias MeasurementStreamID = Int64

public struct MeasurementStreamLocalID {
    let id: NSManagedObjectID
}

@objc(MeasurementStreamEntity)
public class MeasurementStreamEntity: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MeasurementStreamEntity> {
        return NSFetchRequest<MeasurementStreamEntity>(entityName: "MeasurementStreamEntity")
    }

    @NSManaged public var gotDeleted: Bool
    @NSManaged public var measurementShortType: String?
    @NSManaged public var measurementType: String?
    @NSManaged public var sensorName: String?
    @NSManaged public var sensorPackageName: String?
    @NSManaged public var thresholdHigh: Int32
    @NSManaged public var thresholdLow: Int32
    @NSManaged public var thresholdMedium: Int32
    @NSManaged public var thresholdVeryHigh: Int32
    @NSManaged public var thresholdVeryLow: Int32
    @NSManaged public var unitName: String?
    @NSManaged public var unitSymbol: String?
    // Of type MeasurementEntity
    @NSManaged public var measurements: NSOrderedSet?
    @NSManaged public var session: SessionEntity!

    public var id: MeasurementStreamID? {
        get { value(forKey: "id") as? MeasurementStreamID }
        set { setValue(newValue, forKey: "id")}
    }

    public var allMeasurements: [MeasurementEntity]? {
        measurements?.array as? [MeasurementEntity]
    }

    public var localID: MeasurementStreamLocalID {
        MeasurementStreamLocalID(id: objectID)
    }
}

// MARK: Generated accessors for measurements
extension MeasurementStreamEntity {

    @objc(addMeasurementsObject:)
    @NSManaged public func addToMeasurements(_ value: MeasurementEntity)

    @objc(removeMeasurementsObject:)
    @NSManaged public func removeFromMeasurements(_ value: MeasurementEntity)

    @objc(addMeasurements:)
    @NSManaged public func addToMeasurements(_ values: NSSet)

    @objc(removeMeasurements:)
    @NSManaged public func removeFromMeasurements(_ values: NSSet)

}
