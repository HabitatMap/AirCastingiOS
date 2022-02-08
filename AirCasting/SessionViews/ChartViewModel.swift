// Created by Lunar on 30/09/2021.
//

import UIKit
import Charts
import Resolver
import Combine
import SwiftUI

final class ChartViewModel: ObservableObject {
    @Published var entries: [ChartDataEntry] = []
    @Published var chartStartTime: Date?
    @Published var chartEndTime: Date?
    @ObservedObject var session: SessionEntity

    var stream: MeasurementStreamEntity? {
        didSet {
            setupDatabaseHook()
            generateEntries()
        }
    }
    @Injected private var persistence: PersistenceController
    @Injected private var settings: UserSettings

    
    private let numberOfEntries = Constants.Chart.numberOfEntries
    private var cancellables: [AnyCancellable] = []

    deinit {
        stopTimers()
    }
    
    init(session: SessionEntity) {
        self.session = session
        self.chartStartTime = session.endTime
        self.chartEndTime = session.endTime
        if shouldBeUpdatingChartForCurrentSession() {
            startTimers()
            scheduleUIResumeNotification()
        }
        setupHooks()
    }
    
    private func shouldBeUpdatingChartForCurrentSession() -> Bool {
        session.isActive || session.isFollowed || session.status == .NEW
    }

    private func setupHooks() {
        settings.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
            self?.refreshChart()
        }.store(in: &cancellables)
        setupDatabaseHook()
    }
    
    // MARK: Database observing
    
    private var databaseObserver: ChartDatabaseObserver?
    
    private func setupDatabaseHook() {
        databaseObserver = nil
        guard shouldBeUpdatingChartForCurrentSession(), let sensor = stream?.sensorName else { return }
        let filter: ChartDatabaseObserverFilter = session.isFixed ? .hour : .minute(countingFrom: session.startTime?.convertedFromUTCToLocal ?? DateBuilder.getRawDate())
        databaseObserver = ChartDatabaseObserver(session: session.uuid, sensor: sensor, filtered: filter) { [weak self] in
            guard let self = self else { return }
            self.log("Measurements change detected")
            self.generateEntries()
        }
    }
    
    // MARK: Timers
    
    private var timeUnit: TimeInterval {
        session.isMobile ? .minute : .hour
    }

    private var mainTimer: Timer?
    private var firstTimer: Timer?
    private var uiPausedNotificationHandle: Any?
    private var uiResumedNotificationHandle: Any?
    
    private func startMainTimer() {
        Log.verbose("Starting periodic (\(timeUnit)s) timer")
        mainTimer = Timer.scheduledTimer(withTimeInterval: timeUnit, repeats: true) { [weak self] timer in
            Log.verbose("Periodic timer fired")
            self?.generateEntries()
        }
    }

    private func startTimers() {
        let timeOfNextAverage = timeOfNextAverage()
        log("Starting chart timers (time of first entry regen: \(timeOfNextAverage) (\(Date().addingTimeInterval(timeOfNextAverage)))")
        firstTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeOfNextAverage), repeats: false) { [weak self] timer in
            self?.log("Initial timer fired for chart")
            self?.generateEntries()
            self?.startMainTimer()
        }
    }
    
    private func stopTimers() {
        Log.verbose("Stopping chart timers")
        firstTimer?.invalidate()
        mainTimer?.invalidate()
    }
    
    private func timeOfNextAverage() -> Double {
        let sessionStartTime = session.startTime!

        if session.isFixed {
            return DateBuilder.getRawDate().roundedUpToHour.timeIntervalSince(DateBuilder.getRawDate()) + 1
        } else {
            return timeUnit - DateBuilder.getFakeUTCDate().timeIntervalSince(sessionStartTime).truncatingRemainder(dividingBy: timeUnit)
        }
    }

    private func scheduleUIResumeNotification() {
        uiPausedNotificationHandle = NotificationCenter.default.addObserver(forName: PersistenceController.uiDidSuspendNotificationName, object: nil, queue: .main) { [weak self] _ in
            self?.log("Received uiDidSuspendNotificationName. Stopping timers")
            self?.stopTimers()
        }
        uiResumedNotificationHandle = NotificationCenter.default.addObserver(forName: PersistenceController.uiDidResumeNotificationName, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            guard self.shouldBeUpdatingChartForCurrentSession() else { return }
            self.log("Received uiDidSuspendNotificationName. Restarting timers")
            self.generateEntries()
            self.startTimers()
        }
    }
    
    // MARK: Chart refresh

    func refreshChart() {
        generateEntries()
    }

    private func generateEntries() {
        Log.verbose("Generating entries")
        // Set up begning and end of the interval for the first average
        //  - for fixed sessions we are taking the last full hour of the session, which has any measurements
        //  - for mobile we are taking into account full minutes since the session started and we are taking the most recent one
        guard
            stream != nil,
            var intervalEnd = intervalEndTime()
        else {
            Log.warning("Generating entried failed!")
            return
        }

        chartEndTime = intervalEnd
        var endOfFirstInterval = intervalEnd

        var intervalStart = intervalEnd - timeUnit

        var entries = [ChartDataEntry]()
        for i in (0..<numberOfEntries).reversed() {
            if (intervalStart < stream!.session.startTime!.roundedDownToSecond) { break }
            let average = averagedValue(intervalStart, intervalEnd)
            if let average = average {
                entries.append(ChartDataEntry(x: Double(i), y: average))
            }
            endOfFirstInterval = intervalEnd
            intervalEnd = intervalStart
            intervalStart = intervalEnd - timeUnit
        }
        chartStartTime = endOfFirstInterval
        log("Chart entries generated: \(entries)")
        self.entries = entries
    }

    private func intervalEndTime() -> Date? {
        guard let lastMeasurementTime = stream?.lastMeasurementTime else { return nil }
        let sessionStartTime = session.startTime!

        if session.isFixed {
            return (lastMeasurementTime + 120).roundedDownToHour
        } else {
            let secondsSinceFullMinuteFromSessionStart = DateBuilder.getFakeUTCDate().timeIntervalSince(sessionStartTime).truncatingRemainder(dividingBy: timeUnit)
            return DateBuilder.getRawDate().currentUTCTimeZoneDate - secondsSinceFullMinuteFromSessionStart
        }
    }

    private func averagedValue(_ intervalStart: Date, _ intervalEnd: Date) -> Double? {
        guard stream != nil else { return nil }
        let measurements = stream!.getMeasurementsFromTimeRange(intervalStart.roundedDownToSecond, intervalEnd.roundedDownToSecond)
        let values = measurements.map { stream!.isTemperature && settings.convertToCelsius ? TemperatureConverter.calculateCelsius(fahrenheit: $0.value) : $0.value }
        return values.isEmpty ? nil : round(values.reduce(0, +) / Double(values.count))
    }
    
    // MARK: Debugging utils
    
    private func log(_ msg: String) {
        Log.info("\(msg). Session info: [\(logSessionInfo)]")
    }
    
    private var logSessionInfo: String {
        "\(session.uuid ?? "uuid not avilable"), \(session.name ?? "name not available")"
    }
}
