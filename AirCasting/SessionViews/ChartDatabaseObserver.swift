// Created by Lunar on 06/02/2022.
//

import Foundation
import CoreData
import Resolver

enum ChartDatabaseObserverFilter {
    case none
    case hour
    case minute(countingFrom: Date)
}

final class ChartDatabaseObserver {
    @Injected private var persistence: PersistenceController
    private let onMeasurementsChange: (() -> Void)
    private let session: String
    private let sensor: String
    private let filteringComponent: ChartDatabaseObserverFilter
    
    private var latestMeasurementTime: Date?
    
    init(session: String, sensor: String, filtered: ChartDatabaseObserverFilter, onMeasurementsChange: @escaping (() -> Void)) {
        self.onMeasurementsChange = onMeasurementsChange
        self.session = session
        self.sensor = sensor
        self.filteringComponent = filtered
        NotificationCenter.default.addObserver(self, selector: #selector(contextChanged(_:)), name: .NSManagedObjectContextObjectsDidChange, object: persistence.viewContext)
        Log.info("Started database observing service")
    }
    
    @objc private func contextChanged(_ n: Notification) {
        guard let insertedObjects = (n.userInfo?[NSInsertedObjectsKey] as? NSSet)?.allObjects else { return }
        let insertedMeasurements = insertedObjects.compactMap { $0 as? MeasurementEntity }
        let filtered = insertedMeasurements.filter { $0.measurementStream.session?.uuid.rawValue == session ||
            $0.measurementStream.externalSession?.uuid.rawValue == session &&
            $0.measurementStream.sensorName == sensor }
        guard let newestMeasurement = filtered.sorted(by: { $0.time > $1.time }).first else { return }
        defer { latestMeasurementTime = newestMeasurement.time }
        guard filtered.count > 0, shouldFireObserver(newMeasurement: newestMeasurement) else { return }
        Log.info("Firing.\n" +
                 "   New measurement time: \(newestMeasurement.time.debugInfo),\n" +
                 "   session name: \(newestMeasurement.measurementStream.session?.name ?? newestMeasurement.measurementStream.externalSession?.name ?? "??")\n" +
                 "   session start time: \(newestMeasurement.measurementStream.session?.startTime.debugInfo ?? newestMeasurement.measurementStream.externalSession?.startTime.debugDescription),\n" +
                 "   filtering: \(filteringComponent)")
        onMeasurementsChange()
    }
    
    private func shouldFireObserver(newMeasurement: MeasurementEntity) -> Bool {
        switch filteringComponent {
        case .none: return true
        case .hour: return isInNewHour(measurement: newMeasurement)
        case .minute(let countingFrom): return isInNewMinute(measurement: newMeasurement, countingFrom: countingFrom)
        }
    }
    
    private func isInNewHour(measurement: MeasurementEntity) -> Bool {
        guard let latestMeasurementTime = latestMeasurementTime else { return true }
        guard Calendar.current.isDate(latestMeasurementTime, inSameDayAs: measurement.time) else { return true }
        let nowComponent = Calendar.current.component(.hour, from: measurement.time)
        let latestComponent = Calendar.current.component(.hour, from: latestMeasurementTime)
        return latestComponent != nowComponent
    }
    
    private func isInNewMinute(measurement: MeasurementEntity, countingFrom: Date) -> Bool {
        guard let latestMeasurementTime = latestMeasurementTime else { return true }
        guard let newMeasurementTime = measurement.time else { return true }
        let latestMeasurementTimeMinutesFromStart = minuteOfSession(for: latestMeasurementTime, startingDate: countingFrom)
        let newMeasurementMinutesFromStart = minuteOfSession(for: newMeasurementTime, startingDate: countingFrom)
        return newMeasurementMinutesFromStart > latestMeasurementTimeMinutesFromStart
    }
    
    private func minuteOfSession(for date: Date, startingDate: Date) -> Int {
        Int(floor((date.timeIntervalSince(startingDate) / 60)))
    }
}

extension ChartDatabaseObserverFilter: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .none: return "none"
        case .hour: return "hourly"
        case .minute(let start): return "every minute starting from \(start)"
        }
    }
}

fileprivate extension Optional where Wrapped == Date {
    var debugInfo: String {
        switch self {
        case .none: return "??"
        case .some(let date): return DateFormatters.Debug.logsFormatter.string(from: date)
        }
    }
}
