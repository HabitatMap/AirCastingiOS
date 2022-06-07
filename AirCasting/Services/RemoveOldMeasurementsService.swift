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
    func removeOldestMeasurements(in context: NSManagedObjectContext, from sessionUUID: SessionUUID) throws {
        if let session = try? context.existingSession(uuid: sessionUUID) {
            try removeMeasurementsSurplus(context: context, streams: session.allStreams)
        } else {
            let session = try context.existingExternalSession(uuid: sessionUUID)
            try removeMeasurementsSurplus(context: context, streams: session.allStreams, provider: session.provider)
        }
    }
    
    // PurpleAir — measurements from there are not consistent, so we need to do more 'manual work' 🔧
    // OpenAQ — measurements from there are not consistent, so we need to do more 'manual work' 🔧
    // 'manual work' - taking the newest measurement and by having its time we are going back exactly 24 hours
    // AirBeam - measurement every 1 min (60 times/1h): 1440 measurements (per 24 hours)
    private func removeMeasurementsSurplus(context: NSManagedObjectContext, streams: [MeasurementStreamEntity], provider: String = "") throws {
        for stream in streams {
            guard let measurementsCount = stream.measurements?.count else { continue }
            
            switch provider {
            case SensorType.PurpleAir.capitalizedName, SensorType.OpenAQ.capitalizedName: timeBasedRemover(context: context, measurementsCount: measurementsCount, stream: stream); return
            default: numberBasedRemover(for: provider, context: context, measurementsCount: measurementsCount, stream: stream); return
            }
        }
    }
    
    private func numberBasedRemover(for sensor: String, context: NSManagedObjectContext, measurementsCount: Int, stream: MeasurementStreamEntity) {
        let twentyFourMeasurementsCount = RemoveOldMeasurementsService.twentyFourHoursMeasurementCount
        if measurementsCount > twentyFourMeasurementsCount {
            let surplus = stream.allMeasurements?.prefix(measurementsCount - twentyFourMeasurementsCount) ?? []
            for measurement in surplus {
                context.delete(measurement)
            }
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
