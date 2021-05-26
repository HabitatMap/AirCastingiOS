// Created by Lunar on 26/05/2021.
//

import Foundation
import CoreData


final class RemoveOldMeasurementsService {
    
    enum Error: Swift.Error {
        case sessionFetchFailed
        case removingMeasurementsSurplusFailed
        
    }
    private let twentyFourHoursMeasurementCount = 24 * 60
    
    func removeOldestMeasurements(context: NSManagedObjectContext, uuid: SessionUUID) {
        /// In fixed sessions we need to remove measurements older than 24h, but we treat 24 not like a date, but as a sum of measurements.
        /// We know that we have 60 measurements per hour, so we take 1440 last measurements for each stream, and we remove older than the first of them.
        do {
            let session = try fetchSession(context: context, uuid: uuid)
            removeMeasurementsSurplus(context: context, session: session)
        } catch {
            Log.error("Error: \(Error.removingMeasurementsSurplusFailed)")
        }
    }
    
    private func fetchSession(context: NSManagedObjectContext, uuid: SessionUUID) throws -> SessionEntity {
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = request.typePredicate(.fixed)
        request.predicate = NSPredicate(format: "uuid == %@", uuid.rawValue)
        let fetchedSessions = try context.fetch(request)
        
        guard let session = fetchedSessions.first else {
            throw Error.sessionFetchFailed
        }
        return session
    }
    
    private func removeMeasurementsSurplus(context: NSManagedObjectContext, session: SessionEntity) {
        for stream in session.measurementStreams! {
            let stream: MeasurementStreamEntity = stream as! MeasurementStreamEntity
            let measurementsCount = stream.measurements!.count
            
            if measurementsCount > twentyFourHoursMeasurementCount {
                let surplus = stream.allMeasurements?.prefix(measurementsCount - twentyFourHoursMeasurementCount) ?? []
                for measurement in surplus {
                    context.delete(measurement)
                }
            }
        }
    }
}
