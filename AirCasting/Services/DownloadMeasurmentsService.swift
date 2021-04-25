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
    private lazy var fixedSessionService = FixedSessionAPIService(authorisationService: authorisationService)
    private var timerSink: Cancellable?
    private var lastFetchCancellableTask: Cancellable?
    private var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    init(authorisationService: RequestAuthorisationService) {
        self.authorisationService = authorisationService
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
        let request: NSFetchRequest<Session> = Session.fetchRequest()
        request.predicate = request.typePredicate(.fixed)
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
        lastFetchCancellableTask = fixedSessionService.getFixedMeasurement(uuid: uuid, lastSync: syncDate, completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    #warning("TODO: Use different context ")
                    // Fetch session by id from Core Data
                    let context = PersistenceController.shared.container.viewContext
                    do {
                        let session: Session = try context.newOrExisting(uuid: response.uuid)
                        try UpdateSessionParamsService().updateSessionsParams(session: session, output: response)
                        try context.save()
                        Log.info("Successfully fetched fixed measurements")
                    } catch {
                        assertionFailure("Failed to save context \(error)")
                    }
                case .failure(let error):
                    Log.warning("Failed to fetch measurements for uuid '\(uuid)' \(error)")
                }
            }
        })
    }
}
