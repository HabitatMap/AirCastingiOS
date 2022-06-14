import Foundation
import CoreData

final class DefaultRemoveOldMeasurementsService: RemoveOldMeasurements {
    
    enum Error: Swift.Error {
        case removingMeasurementsSurplusFailed
        case noStreamInSession
    }
    
    /// In fixed and external sessions we need to remove measurements older than 24h, and we treat 24 like a date.
    /// We know the time of the last measurement and based on that we are subtracking 24h in seconds.
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
            timeBasedRemover(context: context, stream: stream)
        }
    }
    
    private func timeBasedRemover(context: NSManagedObjectContext, stream: MeasurementStreamEntity) {
        let lastMeasurement = stream.allMeasurements?.last
        let twentyFour = 86400000 // 24 hours in miliseconds: 60 * 60 * 24
        let beginingOfCorrectPeriod = lastMeasurement!.time.milliseconds - twentyFour
        stream.allMeasurements?.reversed().forEach({ measurement in
            if measurement.time.milliseconds < beginingOfCorrectPeriod { context.delete(measurement) }
        })
    }
}
