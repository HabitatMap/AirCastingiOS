import Foundation
import CoreData

final class DefaultOldMeasurementsService: RemoveOldMeasurements {
    
    enum Error: Swift.Error {
        case removingMeasurementsSurplusFailed
        case noStreamInSession
    }
    
    private static let twentyFourHoursMeasurementCount = 24 * 60
    
    /// In fixed sessions we need to remove measurements older than 24h, but we treat 24 not like a date, but as a sum of measurements.
    /// We know that we have 60 measurements per hour, so we take 1440 last measurements for each stream, and we remove older than the first of them.
    func removeOldestMeasurements(in context: NSManagedObjectContext, from sessionUUID: SessionUUID) throws {
        if let session = try? context.existingSession(uuid: sessionUUID) {
            try removeMeasurementsSurplus(context: context, streams: session.allStreams)
        } else {
            let session = try context.existingExternalSession(uuid: sessionUUID)
            try removeMeasurementsSurplus(context: context, streams: session.allStreams)
        }
    }
    
    private func removeMeasurementsSurplus(context: NSManagedObjectContext, streams: [MeasurementStreamEntity]) throws {
        for stream in streams {
            guard let measurementsCount = stream.measurements?.count else { continue }
            numberBasedRemover(context: context, measurementsCount: measurementsCount, stream: stream)
        }
    }
    
    private func numberBasedRemover(context: NSManagedObjectContext, measurementsCount: Int, stream: MeasurementStreamEntity) {
        let twentyFourMeasurementsCount = DefaultOldMeasurementsService.twentyFourHoursMeasurementCount
        if measurementsCount > twentyFourMeasurementsCount {
            let surplus = stream.allMeasurements?.prefix(measurementsCount - twentyFourMeasurementsCount) ?? []
            for measurement in surplus {
                context.delete(measurement)
            }
        }
    }
}
