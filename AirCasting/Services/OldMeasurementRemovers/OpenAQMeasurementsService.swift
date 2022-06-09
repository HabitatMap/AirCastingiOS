import Foundation
import CoreData

final class OpenAQMeasurementsService: RemoveOldMeasurementsOpenAQ {
    // OpenAQ — measurements from there are not consistent, so we need to do more 'manual work' 🔧
    // 'manual work' - taking the newest measurement and by having its time we are going back exactly 24 hours
    
    enum Error: Swift.Error {
        case removingMeasurementsSurplusFailed
        case noStreamInSession
    }
    
    func removeOldestMeasurements(in context: NSManagedObjectContext, from sessionUUID: SessionUUID) throws {
        let session = try context.existingExternalSession(uuid: sessionUUID)
        try removeMeasurementsSurplus(context: context, streams: session.allStreams)
    }
    
    private func removeMeasurementsSurplus(context: NSManagedObjectContext, streams: [MeasurementStreamEntity]) throws {
        for stream in streams {
            guard let measurementsCount = stream.measurements?.count else { continue }
            timeBasedRemover(context: context, measurementsCount: measurementsCount, stream: stream)
        }
    }
    
    private func timeBasedRemover(context: NSManagedObjectContext, measurementsCount: Int, stream: MeasurementStreamEntity) {
        let lastMeasurement = stream.allMeasurements?.last
        let twentyFour = 86400000 // 24 hours in miliseconds: 60 * 60 * 24
        let beginingOfCorrectPeriod = lastMeasurement!.time.milliseconds - twentyFour
        stream.allMeasurements?.reversed().forEach({ measurement in
            if measurement.time.milliseconds < beginingOfCorrectPeriod { context.delete(measurement) }
        })
    }
}
