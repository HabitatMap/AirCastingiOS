//
//  DownloadMeasurmentsService.swift
//  AirCasting
//
//  Created by Lunar on 25/03/2021.
//

import Foundation
import CoreData

class DownloadMeasurementsService: ObservableObject {

    var timer = Timer.publish(every: 60, on: .current, in: .common).autoconnect()
    var timerSink: Any?
    private var sink: Any?
    var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }

    func start() {
        timerSink = timer.sink { [weak self] timer in
            do {
                try self?.update()
            } catch {
                assertionFailure("Failed to call update at \(timer) \(error)")
            }
        }
    }
    
    private func updateForSession(uuid: UUID) {
        //TODO: change last sync
        let syncDate = Date().addingTimeInterval(-100)
        sink = FixedSession
            .getFixedMeasurement(uuid: uuid,
                                 lastSync: syncDate)
            .sink { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    Log.warning("Failed to fetch measurements for uuid '\(uuid)' \(error)")
                }
            } receiveValue: { fixedMeasurementOutput in
                DispatchQueue.main.async {
                    #warning("TODO: Use different context ")
                    // Fetch session by id from Core Data
                    let context = PersistenceController.shared.container.viewContext
                    let session: Session = context.newOrExisting(uuid: fixedMeasurementOutput.uuid.uuidString)
                    UpdateSessionParamsService().updateSessionsParams(session: session, output: fixedMeasurementOutput)
                    do {
                        try context.save()
                        Log.info("Successfully fetched fixed measurements")
                    } catch {
                        assertionFailure("Failed to save context \(error)")
                    }
                }
            }
    }
    
    func update() throws {
        let request: NSFetchRequest<Session> = Session.fetchRequest()
        let fetchedResult = try context.fetch(request)
        for session in fetchedResult {
            if let uuid = session.uuid.flatMap(UUID.init(uuidString:)) {
                updateForSession(uuid: uuid)
            } else {
                Log.error("trying to refresh session without uuid \(session)")
            }
        }
    }
}
