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
        timerSink = timer.sink { [weak self] (_) in
            self?.update()
        }
    }
    
    private func update() {
        let uuid = UUID(uuidString: "fcb242f0-fdba-4c9b-943e-51adff1aebac")!
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
                let fetchRequest = NSFetchRequest<Session>(entityName: "Session")
                fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid.uuidString.lowercased())
                let results = try! self.context.fetch(fetchRequest)
                guard let session = results.first else {
                    return
                }
                                
                UpdateSessionParamsService().updateSessionsParams(session: session, output: fixedMeasurementOutput)
                
                try! self.context.save()
                print("Yay! UPDATED SESSION! :D ")
            }
    }
}
