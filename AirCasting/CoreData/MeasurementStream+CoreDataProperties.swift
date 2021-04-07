//
//  MeasurementStream+CoreDataProperties.swift
//  AirCasting
//
//  Created by Lunar on 01/04/2021.
//
//

import Foundation
import CoreData


extension MeasurementStream {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MeasurementStream> {
        return NSFetchRequest<MeasurementStream>(entityName: "MeasurementStream")
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
    @NSManaged public var id: Int64
    @NSManaged public var measurements: NSSet?
    @NSManaged public var session: Session?

}

// MARK: Generated accessors for measurements
extension MeasurementStream {

    @objc(addMeasurementsObject:)
    @NSManaged public func addToMeasurements(_ value: Measurement)

    @objc(removeMeasurementsObject:)
    @NSManaged public func removeFromMeasurements(_ value: Measurement)

    @objc(addMeasurements:)
    @NSManaged public func addToMeasurements(_ values: NSSet)

    @objc(removeMeasurements:)
    @NSManaged public func removeFromMeasurements(_ values: NSSet)

}

extension MeasurementStream : Identifiable {

}
