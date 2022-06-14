import Foundation
import CoreData

protocol RemoveOldMeasurements {
    func removeOldestMeasurements(in context: NSManagedObjectContext, from sessionUUID: SessionUUID) throws
}
