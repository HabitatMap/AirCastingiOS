// Created by Lunar on 06/02/2022.
//

import Foundation
import CoreData
import Resolver

enum ChartDatabaseObserverFilter {
    case none
    case hour
    case minute
}

final class ChartDatabaseObserver {
    @Injected private var persistence: PersistenceController
    private let onMeasurementsChange: (() -> Void)
    private let session: SessionUUID
    private let sensor: String
    private let filteringComponent: Calendar.Component?
    
    private var lastMeasurementChangeAt: Date?
    
    init(session: SessionUUID, sensor: String, timedFilter: ChartDatabaseObserverFilter, onMeasurementsChange: @escaping (() -> Void)) {
        self.onMeasurementsChange = onMeasurementsChange
        self.session = session
        self.sensor = sensor
        self.filteringComponent = timedFilter.calendarComponent
        NotificationCenter.default.addObserver(self, selector: #selector(contextChanged(_:)), name: .NSManagedObjectContextObjectsDidChange, object: persistence.viewContext)
        Log.info("Started database observing service")
    }
    
    @objc private func contextChanged(_ n: Notification) {
        guard let insertedObjects = (n.userInfo?[NSInsertedObjectsKey] as? NSSet)?.allObjects else { return }
        let insertedMeasurements = insertedObjects.compactMap { $0 as? MeasurementEntity }
        let filtered = insertedMeasurements.filter { $0.measurementStream.session.uuid == session && $0.measurementStream.sensorName == sensor }
        guard filtered.count > 0, shouldFireObserver() else { return }
        lastMeasurementChangeAt = DateBuilder.getRawDate()
        onMeasurementsChange()
    }
    
    private func shouldFireObserver() -> Bool {
        guard let lastMeasurementChangeAt = lastMeasurementChangeAt, let filteringComponent = filteringComponent else { return true }
        let now = DateBuilder.getRawDate()
        guard Calendar.current.isDate(lastMeasurementChangeAt, inSameDayAs: now) else { return true }
        let nowComponent = Calendar.current.component(filteringComponent, from: now)
        let lastMeasurementComponent = Calendar.current.component(filteringComponent, from: lastMeasurementChangeAt)
        return lastMeasurementComponent != nowComponent
    }
}

fileprivate extension ChartDatabaseObserverFilter {
    var calendarComponent: Calendar.Component? {
        switch self {
        case .none: return nil
        case .hour: return .hour
        case .minute: return .minute
        }
    }
}
