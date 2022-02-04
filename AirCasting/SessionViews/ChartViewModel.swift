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
            guard session.isActive || session.isFollowed || session.status == .NEW else { return }
            generateEntries()
        }
    }
    @Injected private var persistence: PersistenceController
    @Injected private var settings: UserSettings

    private var timeUnit: TimeInterval {
        session.isMobile ? .minute : .hour
    }

    private var mainTimer: Timer?
    private var firstTimer: Timer?
    private let numberOfEntries = Constants.Chart.numberOfEntries

    private var uiResumedNotificationHandle: Any?
    private var cancellables: [AnyCancellable] = []

    deinit {
        mainTimer?.invalidate()
        firstTimer?.invalidate()
    }
    
    init(session: SessionEntity) {
        self.session = session
        self.chartStartTime = session.endTime
        self.chartEndTime = session.endTime
        if session.isActive || session.isFollowed || session.status == .NEW {
            startTimers(session)
            scheduleUIResumeNotification()
        }
        setupHooks()
    }

    private func setupHooks() {
        settings.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
            self?.refreshChart()
        }.store(in: &cancellables)
    }

    private func startTimers(_ session: SessionEntity) {
        let timeOfNextAverage = timeOfNextAverage()
        firstTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeOfNextAverage), repeats: false) { [weak self] timer in
            self?.generateEntries()
            self?.startMainTimer()
        }
    }

    private func scheduleUIResumeNotification() {
        uiResumedNotificationHandle = NotificationCenter.default.addObserver(forName: PersistenceController.uiDidResumeNotificationName, object: nil, queue: .main) { [weak self] _ in
            self?.generateEntries()
        }
    }

    func startMainTimer() {
        mainTimer = Timer.scheduledTimer(withTimeInterval: timeUnit, repeats: true) { [weak self] timer in
            self?.generateEntries()
        }
    }

    func refreshChart() {
        generateEntries()
    }

    private func generateEntries() {
        // Set up begning and end of the interval for the first average
        //  - for fixed sessions we are taking the last full hour of the session, which has any measurements
        //  - for mobile we are taking into account full minutes since the session started and we are taking the most recent one
        guard
            stream != nil,
            var intervalEnd = intervalEndTime()
        else {
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
        self.entries = entries
    }

    private func intervalEndTime() -> Date? {
        guard let lastMeasurementTime = stream?.lastMeasurementTime else { return nil }
        let sessionStartTime = session.startTime!

        if session.isFixed {
            return (lastMeasurementTime + 60).roundedDownToHour
        } else {
            let secondsSinceFullMinuteFromSessionStart = DateBuilder.getFakeUTCDate().timeIntervalSince(sessionStartTime).truncatingRemainder(dividingBy: timeUnit)
            return DateBuilder.getRawDate().currentUTCTimeZoneDate - secondsSinceFullMinuteFromSessionStart
        }
    }

    private func timeOfNextAverage() -> Double {
        let sessionStartTime = session.startTime!

        if session.isFixed {
            return DateBuilder.getRawDate().roundedUpToHour.timeIntervalSince(DateBuilder.getRawDate())
        } else {
            return timeUnit - DateBuilder.getFakeUTCDate().timeIntervalSince(sessionStartTime).truncatingRemainder(dividingBy: timeUnit)
        }
    }

    private func averagedValue(_ intervalStart: Date, _ intervalEnd: Date) -> Double? {
        guard stream != nil else { return nil }
        let measurements = stream!.getMeasurementsFromTimeRange(intervalStart.roundedDownToSecond, intervalEnd.roundedDownToSecond)
        let values = measurements.map { stream!.isTemperature && settings.convertToCelsius ? TemperatureConverter.calculateCelsius(fahrenheit: $0.value) : $0.value }
        return values.isEmpty ? nil : round(values.reduce(0, +) / Double(values.count))
    }
}
