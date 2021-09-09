//
//  DownloadMeasurmentsService.swift
//  AirCasting
//
//  Created by Lunar on 25/03/2021.
//

import Foundation
import CoreData
import Combine

protocol MeasurementUpdatingService {
    func start() throws
}

final class DownloadMeasurementsService: MeasurementUpdatingService {
    private let authorisationService: RequestAuthorisationService
    private let persistenceController: PersistenceController
    private let fixedSessionService: FixedSessionAPIService
    private var timerSink: Cancellable?
    private var lastFetchCancellableTask: Cancellable?
    private lazy var removeOldService: RemoveOldMeasurementsService = RemoveOldMeasurementsService()
    
    init(authorisationService: RequestAuthorisationService, persistenceController: PersistenceController, baseUrl: BaseURLProvider) {
        self.authorisationService = authorisationService
        self.persistenceController = persistenceController
        self.fixedSessionService = FixedSessionAPIService(authorisationService: authorisationService, baseUrl: baseUrl)
    }

    func start() throws {
        try update()
        timerSink = Timer.publish(every: 60, on: .current, in: .common).autoconnect().sink { [weak self] tick in
            do {
                Log.info("Triggering scheduled measurement update")
                try self?.update()
            } catch {
                assertionFailure("Failed to call update at \(tick) \(error)")
            }
        }
    }

    private func update() throws {
        let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
        request.predicate = request.typePredicate(.fixed)
        let context = persistenceController.viewContext
        let fetchedResult = try context.fetch(request)
        for session in fetchedResult {
            if let uuid = session.uuid {
                updateForSession(uuid: uuid)
            } else {
                Log.error("trying to refresh session without uuid \(session)")
            }
        }
    }
    
    private func updateForSession(uuid: SessionUUID) {        
        let session = try? persistenceController.viewContext.existingSession(uuid: uuid)
        let lastMeasurementTime = session?.allStreams?
            .compactMap(\.lastMeasurementTime)
            .sorted()
            .last
        let syncDate = SyncHelper().calculateLastSync(sessionEndTime: session?.endTime, lastMeasurementTime: lastMeasurementTime)
        
        lastFetchCancellableTask = fixedSessionService.getFixedMeasurement(uuid: uuid, lastSync: syncDate, completion: { [removeOldService, persistenceController] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let context = persistenceController.editContext()
                    do {
                        let session: SessionEntity = try context.newOrExisting(uuid: response.uuid)
                        try UpdateSessionParamsService().updateSessionsParams(session: session, output: response)
                        try context.save()
                        Log.info("Successfully fetched fixed measurements")
                    } catch {
                        assertionFailure("Failed to save context \(error)")
                    }
                    persistenceController.performBackgroundTask { bgContext in
                        do {
                            try removeOldService.removeOldestMeasurements(in: bgContext,
                                                                          uuid: uuid)
                        } catch {
                            Log.error("Failed to remove old measaurements from fixed session \(error)")
                        }
                    }
                case .failure(let error):
                    Log.warning("Failed to fetch measurements for uuid '\(uuid)' \(error)")
                }
            }
        })
    }
}

class SyncHelper {
    
    func calculateLastSync(sessionEndTime: Date?, lastMeasurementTime: Date?) -> Date {
        let measurementTimeframe: Double = 24 * 60 * 60 // 24 hours in seconds
        
        guard let sessionEndTime = sessionEndTime else { return Date() }
        let sessionEndTimeSeconds = sessionEndTime.timeIntervalSince1970
        
        let last24hours = Date(timeIntervalSince1970: (sessionEndTimeSeconds - measurementTimeframe))
        
        guard let lastMeasurementTime = lastMeasurementTime else { return last24hours }
        let lastMeasurementSeconds = lastMeasurementTime.timeIntervalSince1970
        
        return ((sessionEndTimeSeconds - lastMeasurementSeconds) < measurementTimeframe) ? lastMeasurementTime : last24hours
    }
}
