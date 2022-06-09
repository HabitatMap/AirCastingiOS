import Foundation
import CoreData

protocol RemoveOldMeasurements {
    func removeOldestMeasurements(in context: NSManagedObjectContext, from sessionUUID: SessionUUID) throws
}

protocol RemoveOldMeasurementsOpenAQ {
    func removeOldestMeasurements(in context: NSManagedObjectContext, from sessionUUID: SessionUUID) throws
}

protocol RemoveOldMeasurementsPurpleAir {
    func removeOldestMeasurements(in context: NSManagedObjectContext, from sessionUUID: SessionUUID) throws
}
