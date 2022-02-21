//
//  Persistance.swift
//  AirCasting
//
//  Created by Anna Olak on 04/03/2021.
//

import CoreData
import SwiftUI

class PersistenceController: ObservableObject {
    static let uiWillSuspendNotificationName = NSNotification.Name("uiWillSuspendNotification")
    static let uiWillResumeNotificationName = NSNotification.Name("uiWillResumeNotificationName")
    static let uiDidSuspendNotificationName = NSNotification.Name("uiDidSuspendNotification")
    static let uiDidResumeNotificationName = NSNotification.Name("uiDidResumeNotificationName")
    
    var uiSuspended: Bool = false {
        willSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: newValue ? Self.uiWillSuspendNotificationName : Self.uiWillResumeNotificationName, object: self)
            }
        }
        didSet {
            Log.info("UI updates \(uiSuspended ? "suspended" : "resumed")")
            
            if !uiSuspended {
                propagateChangesToUI() {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Self.uiDidResumeNotificationName, object: self)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Self.uiDidSuspendNotificationName, object: self)
                }
            }
            
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
    
    lazy var editContext: NSManagedObjectContext = {
        let ctx = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        ctx.parent = sourceOfTruthContext
        ctx.automaticallyMergesChangesFromParent = true
        return ctx
    }()
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = editContext
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
            Log.info("UI suspended, not propagating changes!")
            return
        }
        propagateChangesToUI()
    }
    
    @objc private func appWillClose() {
        Log.info("Application termination, saving data")
        saveMainContext()
    }
    
    private func propagateChangesToUI(completion: (()->Void)? = nil) {
        saveMainContext(completion: completion)
    }
    
    private func saveMainContext(completion: (()->Void)? = nil) {
        sourceOfTruthContext.perform {
            try! self.sourceOfTruthContext.save()
            completion?()
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
        let thresholdVeryLow: Int32 = 20
        let thresholdLow: Int32 = 60
        let thresholdMedium: Int32 = 70
        let thresholdHigh: Int32 = 80
        let thresholdVeryHigh: Int32 = 100
    }

    private func finishMobileSessions() {
        container.performBackgroundTask { context in
            let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "type == %@ && status IN %@ || deviceType == %@ && status IN %@", SessionType.mobile.rawValue, [SessionStatus.RECORDING, .NEW].map(\.rawValue), DeviceType.MIC.rawValue, [SessionStatus.DISCONNECTED.rawValue])
            let sessions = try! context.fetch(request)
            if sessions.isEmpty {
                return
            }
            Log.info("Finishing sessions \( sessions.map({ "\(String(describing: $0.uuid)): \(String(describing: $0.status)) \(String(describing: $0.type))"}) )")
            sessions.forEach {
                $0.status = .FINISHED
                $0.endTime = $0.lastMeasurementTime ?? $0.startTime
            }
            try! context.save()
        }
    }
}
