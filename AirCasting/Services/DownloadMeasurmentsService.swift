//
//  DownloadMeasurmentsService.swift
//  AirCasting
//
//  Created by Lunar on 25/03/2021.
//

import Foundation
import CoreData

class DownloadMeasurementsService: ObservableObject {
    
    var timer = Timer.publish(every: 15, on: .current, in: .common).autoconnect()
    var timerSink: Any?
    private var sink: Any?
    var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    
    func start() {
        timerSink = timer.sink { [weak self] (_) in
            self?.update()
        }
    }
    
    private func updateForSession(uuid: UUID) {
        let syncDate = Date().addingTimeInterval(-8000)
        sink = FixedSession
            .getFixedMeasurement(uuid: uuid,
                                 lastSync: syncDate)
            .sink { (completion) in
                switch completion {
                case .finished:
                    print("sucess")
                case .failure(let error):
                    print("ERROR: \(error)")
                }
            } receiveValue: { [weak self] (fixedMeasurementOutput) in
                guard let self = self else { return }
                
                // Fetch session by id from Core Data
                let session: Session = self.context.newOrExisting(uuid: fixedMeasurementOutput.uuid)
                UpdateSessionParamsService().updateSessionsParams(session: session, output: fixedMeasurementOutput)
                
                try! self.context.save()
            }
    }
    
    func update() {
        let request = NSFetchRequest<Session>(entityName: "Session")
        guard let fetchedResult = try? context.fetch(request) else {return}
        
        for session in fetchedResult {
            print("!!!!!!!! getting measaurement for \(session.uuid!)")
            guard let uuid = UUID(uuidString: session.uuid!) else {continue}
            updateForSession(uuid: uuid)
        }
    }
}
