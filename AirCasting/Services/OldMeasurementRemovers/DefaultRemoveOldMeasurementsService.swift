import Foundation
import CoreData
import Resolver

protocol RemoveOldMeasurements {
    func removeOldestMeasurements(in context: NSManagedObjectContext, from sessionUUID: SessionUUID) throws
}

final class DefaultRemoveOldMeasurementsService: RemoveOldMeasurements {
    
    enum Error: Swift.Error {
        case removingMeasurementsSurplusFailed
        case noStreamInSession
    }
    
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    
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
        guard let lastMeasurementTime = stream.allMeasurements?.last?.time else { Log.error("No last measurement when trying to remove those from > 24h"); return }
        let threshold = lastMeasurementTime.twentyFourHoursBefore
        let result = context.deleteMeasurements(thresholdInMiliseconds: threshold, stream: stream)
        switch result {
        case .success(let success):
            try! context.save()
            Log.info(success)
        case .failure(let error):
            Log.error(error.localizedDescription)
        }
    }
}

extension Date {
    var twentyFourHoursBefore: Double {
        let twentyFourHours = 86400000 // 24 hours in miliseconds: 60 * 60 * 24
        return Double(self.milliseconds - twentyFourHours)
    }
}
