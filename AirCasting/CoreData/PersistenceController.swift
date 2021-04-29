//
//  Persistance.swift
//  AirCasting
//
//  Created by Anna Olak on 04/03/2021.
//

import CoreData

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    private let container: NSPersistentContainer

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
        container.viewContext.automaticallyMergesChangesFromParent = true
        createInitialMicThreshold(in: viewContext)

    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    func editContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }

    #warning("Think if we need this in the database at all")
    private func createInitialMicThreshold(in context: NSManagedObjectContext) {
        let existing: SensorThreshold? = try? context.existingObject(sensorName: "db")
        if existing == nil {
            let thresholds: SensorThreshold = try! context.createObject(sensorName: "db")
            #warning("TODO: change thresholds values from dbFS to db")
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
        let thresholdVeryLow: Int32 = -100
        let thresholdLow: Int32 = -40
        let thresholdMedium: Int32 = -30
        let thresholdHigh: Int32 = -20
        let thresholdVeryHigh: Int32 = 10
    }
}
