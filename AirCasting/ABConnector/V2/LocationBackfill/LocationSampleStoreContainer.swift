// V2 disconnect-window location backfill.
//
// Dedicated NSPersistentContainer for the sample store. The shared
// PersistenceController gates `sourceOfTruthContext.save()` on
// `!uiSuspended` (see `PersistenceController.mainContextChanged`), which
// means inserts piggybacked on it never reach disk while the app is
// backgrounded. Long mobile sessions (2 h+) would accumulate thousands of
// in-memory samples that vanish if iOS jetsams the process. This container
// owns its own sqlite file and saves to disk on every insert, regardless
// of the app's UI suspension state.

import Foundation
import CoreData

enum LocationSampleStoreContainer {
    /// Lazily-built, app-wide container. Shared because CoreData expects a
    /// single coordinator per sqlite file.
    static let shared: NSPersistentContainer = {
        let model = Self.makeModel()
        let container = NSPersistentContainer(name: "LocationSamples",
                                              managedObjectModel: model)
        let storeURL = Self.storeURL()
        let description = NSPersistentStoreDescription(url: storeURL)
        description.type = NSSQLiteStoreType
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                Log.error("LocationSampleStoreContainer: load failed: \(error)")
                fatalError("LocationSampleStoreContainer load failed: \(error)")
            }
        }
        Log.info("LocationSampleStoreContainer: loaded store at \(storeURL.path)")
        return container
    }()

    private static func storeURL() -> URL {
        let fm = FileManager.default
        let supportDir: URL
        do {
            supportDir = try fm.url(for: .applicationSupportDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: true)
        } catch {
            Log.error("LocationSampleStoreContainer: app-support unavailable, falling back to caches: \(error)")
            return fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("LocationSamples.sqlite")
        }
        return supportDir.appendingPathComponent("LocationSamples.sqlite")
    }

    /// Programmatic model — keeps the dedicated store independent of the
    /// main `AirCasting.xcdatamodeld` schema so adding/removing unrelated
    /// entities there never triggers a migration on this store.
    private static func makeModel() -> NSManagedObjectModel {
        let entity = NSEntityDescription()
        entity.name = "LocationSampleEntity"
        // Set the managed object class by name string rather than via
        // `NSStringFromClass(LocationSampleEntity.self)`: the autogen class
        // statically binds to the v11 xcdatamodel entity, and calling its
        // `entity()` class method here would return the v11 description
        // instead of this one. The string lookup keeps the dedicated store
        // wired to the programmatic model exclusively.
        entity.managedObjectClassName = "LocationSampleEntity"

        let latitude = NSAttributeDescription()
        latitude.name = "latitude"
        latitude.attributeType = .doubleAttributeType
        latitude.isOptional = false
        latitude.defaultValue = 0.0

        let longitude = NSAttributeDescription()
        longitude.name = "longitude"
        longitude.attributeType = .doubleAttributeType
        longitude.isOptional = false
        longitude.defaultValue = 0.0

        let sessionUUID = NSAttributeDescription()
        sessionUUID.name = "sessionUUID"
        sessionUUID.attributeType = .stringAttributeType
        sessionUUID.isOptional = false

        let timestamp = NSAttributeDescription()
        timestamp.name = "timestamp"
        timestamp.attributeType = .dateAttributeType
        timestamp.isOptional = false

        entity.properties = [latitude, longitude, sessionUUID, timestamp]

        let uuidIndex = NSFetchIndexDescription(
            name: "byUUIDTimestamp",
            elements: [
                NSFetchIndexElementDescription(property: sessionUUID, collationType: .binary),
                NSFetchIndexElementDescription(property: timestamp, collationType: .binary)
            ]
        )
        entity.indexes = [uuidIndex]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }
}
