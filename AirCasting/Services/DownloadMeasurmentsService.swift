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
    private lazy var fixedSessionService = FixedSessionAPIService(authorisationService: authorisationService)
    private var timerSink: Cancellable?
    private var lastFetchCancellableTask: Cancellable?
    private lazy var removeOldService: RemoveOldMeasurementsService = RemoveOldMeasurementsService()
    
    init(authorisationService: RequestAuthorisationService, persistenceController: PersistenceController) {
        self.authorisationService = authorisationService
        self.persistenceController = persistenceController
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
        #warning("TODO: change last sync")
        let syncDate = Date().addingTimeInterval(-100)
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
