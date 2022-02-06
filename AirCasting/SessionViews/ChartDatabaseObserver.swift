// Created by Lunar on 06/02/2022.
//

import Foundation
import CoreData
import Resolver

final class ChartDatabaseObserver {
    @Injected private var persistence: PersistenceController
    private let onMeasurementsChange: (() -> Void)
    private let session: SessionUUID
    private let sensor: String
    
    init(session: SessionUUID, sensor: String, onMeasurementsChange: @escaping (() -> Void)) {
        self.onMeasurementsChange = onMeasurementsChange
        self.session = session
        self.sensor = sensor
        NotificationCenter.default.addObserver(self, selector: #selector(contextChanged(_:)), name: .NSManagedObjectContextObjectsDidChange, object: persistence.viewContext)
        Log.info("Started database observing service")
    }
    
    @objc private func contextChanged(_ n: Notification) {
        guard let insertedObjects = (n.userInfo?[NSInsertedObjectsKey] as? NSSet)?.allObjects else { return }
        let insertedMeasurements = insertedObjects.compactMap { $0 as? MeasurementEntity }
        let filtered = insertedMeasurements.filter { $0.measurementStream.session.uuid == session && $0.measurementStream.sensorName == sensor }
        guard filtered.count > 0 else { return }
        onMeasurementsChange()
    }
}
