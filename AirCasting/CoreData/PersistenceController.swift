//
//  Persistance.swift
//  AirCasting
//
//  Created by Anna Olak on 04/03/2021.
//

import CoreData
import SwiftUI

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    var uiSuspended: Bool = false {
        didSet {
            Log.info("UI updates \(uiSuspended ? "suspended" : "resumed")")
            if !uiSuspended { propagateChangesToUI() }
        }
    }
    
    private(set) lazy var viewContext: NSManagedObjectContext = {
        let ctx = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        ctx.parent = sourceOfTruthContext
        ctx.automaticallyMergesChangesFromParent = true
        return ctx
    }()
    
    private let container: NSPersistentContainer
    
    private lazy var sourceOfTruthContext: NSManagedObjectContext = container.newBackgroundContext()

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AirCasting")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        createInitialMicThreshold(in: viewContext)
        finishMobileSessions()
        NotificationCenter.default.addObserver(self, selector: #selector(mainContextChanged), name: .NSManagedObjectContextObjectsDidChange, object: self.sourceOfTruthContext)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillClose), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    func editContext() -> NSManagedObjectContext {
        let ctx = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        ctx.parent = sourceOfTruthContext
        return ctx
    }
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = editContext()
        context.perform {
            do {
                block(context)
                try context.save()
            } catch {
                Log.error("Couldn't save context! \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func mainContextChanged() {
        guard !uiSuspended else {
            return
        }
        propagateChangesToUI()
    }
    
    @objc private func appWillClose() {
        Log.info("Application termination, saving data")
        saveMainContext()
    }
    
    private func propagateChangesToUI() {
        saveMainContext()
    }
    
    private func saveMainContext() {
        sourceOfTruthContext.perform {
            try! self.sourceOfTruthContext.save()
        }
    }

    private func createInitialMicThreshold(in context: NSManagedObjectContext) {
        let existing: SensorThreshold? = try? context.existingObject(sensorName: "db")
        if existing == nil {
            let thresholds: SensorThreshold = try! context.createObject(sensorName: "db")
            let defaults = DefaultMicThresholdsValues()
            thresholds.thresholdVeryLow = defaults.thresholdVeryLow
            thresholds.thresholdLow = defaults.thresholdLow
            thresholds.thresholdMedium = defaults.thresholdMedium
            thresholds.thresholdHigh = defaults.thresholdHigh
            thresholds.thresholdVeryHigh = defaults.thresholdVeryHigh
            try! context.save()
        }
    }

    private struct DefaultMicThresholdsValues {
        let thresholdVeryLow: Int32 = 100
        let thresholdLow: Int32 = 80
        let thresholdMedium: Int32 = 70
        let thresholdHigh: Int32 = 60
        let thresholdVeryHigh: Int32 = 20
    }

    private func finishMobileSessions() {
        container.performBackgroundTask { context in
            let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "type == %@ && status IN %@", SessionType.mobile.rawValue, [SessionStatus.RECORDING, .DISCONNECTED, .NEW].map(\.rawValue))
            let sessions = try! context.fetch(request)
            if sessions.isEmpty {
                return
            }
            Log.info("Finishing sessions \( sessions.map({ "\(String(describing: $0.uuid)): \(String(describing: $0.status)) \(String(describing: $0.type))"}) )")
            sessions.forEach {
                $0.status = .FINISHED
            }
            try! context.save()
        }
    }
}
