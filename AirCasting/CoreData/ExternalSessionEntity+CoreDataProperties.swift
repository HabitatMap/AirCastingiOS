//
//  ExternalSessionEntity+CoreDataProperties.swift
//  
//
//  Created by Lunar on 06/05/2022.
//
//

import Foundation
import CoreData


extension ExternalSessionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExternalSessionEntity> {
        return NSFetchRequest<ExternalSessionEntity>(entityName: "ExternalSessionEntity")
    }

    @NSManaged public var endTime: Date?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var provider: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var uuid: String?
    @NSManaged public var measurementStreams: NSSet?
    @NSManaged public var uiState: UIStateEntity?

}

// MARK: Generated accessors for measurementStreams
extension ExternalSessionEntity {

    @objc(addMeasurementStreamsObject:)
    @NSManaged public func addToMeasurementStreams(_ value: MeasurementStreamEntity)

    @objc(removeMeasurementStreamsObject:)
    @NSManaged public func removeFromMeasurementStreams(_ value: MeasurementStreamEntity)

    @objc(addMeasurementStreams:)
    @NSManaged public func addToMeasurementStreams(_ values: NSSet)

    @objc(removeMeasurementStreams:)
    @NSManaged public func removeFromMeasurementStreams(_ values: NSSet)

}
