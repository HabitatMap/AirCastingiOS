// Created by Lunar on 26/05/2021.
//

import Foundation
import CoreData


final class RemoveOldMeasurementsService {
    
    enum Error: Swift.Error {
        case removingMeasurementsSurplusFailed
        case noStreamInSession
    }
    
    private static let twentyFourHoursMeasurementCount = 24 * 60
    
    /// In fixed sessions we need to remove measurements older than 24h, but we treat 24 not like a date, but as a sum of measurements.
    /// We know that we have 60 measurements per hour, so we take 1440 last measurements for each stream, and we remove older than the first of them.
    func removeOldestMeasurements(in context: NSManagedObjectContext, uuid: SessionUUID) throws {
        let session = try context.existingSession(uuid: uuid)
        try removeMeasurementsSurplus(context: context, session: session)
    }
    
    private func removeMeasurementsSurplus(context: NSManagedObjectContext, session: SessionEntity) throws {
        guard let streams = session.measurementStreams?.array as? [MeasurementStreamEntity] else { throw Error.noStreamInSession }
        
        for stream in streams {
            guard let measurementsCount = stream.measurements?.count else { continue }
            
            if measurementsCount > RemoveOldMeasurementsService.twentyFourHoursMeasurementCount {
                let surplus = stream.allMeasurements?.prefix(measurementsCount - RemoveOldMeasurementsService.twentyFourHoursMeasurementCount) ?? []
                for measurement in surplus {
                    context.delete(measurement)
                }
            }
        }
    }
}
