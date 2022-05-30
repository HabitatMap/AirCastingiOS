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
    var session: Sessionable

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
    
    init(session: Sessionable, stream: MeasurementStreamEntity?) {
        self.session = session
        self.chartStartTime = session.endTime
        self.chartEndTime = session.endTime
        setupHooks()
        self.stream = stream ?? session.sortedStreams.first
        setupDatabaseHook()
        generateEntries()
    }

    private func setupHooks() {
        settings.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
            self?.generateEntries()
        }.store(in: &cancellables)
        setupDatabaseHook()
    }
    
    // MARK: Database observing
    
    private var databaseObserver: ChartDatabaseObserver?
    
    private func setupDatabaseHook() {
        databaseObserver = nil
        guard let sensor = stream?.sensorName else { return }
        let filter: ChartDatabaseObserverFilter = session.isFixed ? .hour : .minute(countingFrom: session.startTime?.convertedFromUTCToLocal ?? DateBuilder.getRawDate())
        databaseObserver = ChartDatabaseObserver(session: session.uuid?.rawValue ?? "", sensor: sensor, filtered: filter) { [weak self] in
            guard let self = self else { return }
            self.log("Measurements change detected")
            self.generateEntries()
        }
    }
    
    // MARK: Chart refresh
    
    private var timeUnit: TimeInterval {
        session.isMobile ? .minute : .hour
    }

    private func generateEntries() {
        log("Generating entries", level: .verbose)
        // Set up begning and end of the interval for the first average
        //  - for fixed sessions we are taking the last full hour of the session, which has any measurements
        //  - for mobile we are taking into account full minutes since the session started and we are taking the most recent one
        guard
            stream != nil,
            var intervalEnd = intervalEndTime()
        else {
            log("Not generating entries - stream is nil.")
            return
        }

        chartEndTime = intervalEnd
        var endOfFirstInterval = intervalEnd

        var intervalStart = intervalEnd - timeUnit

        var entries = [ChartDataEntry]()
        for i in (0..<numberOfEntries).reversed() {
            if (intervalStart < session.startTime!.roundedDownToSecond) {
                if session.isFixed {
                    let average = averagedValue(intervalStart, intervalEnd)
                    if let average = average {
                        entries.append(ChartDataEntry(x: Double(i), y: average))
                    }
                }
                break
            }
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
    
    private func log(_ msg: String, level: LogLevel = .info, file: String = #fileID, function: String = #function, line: Int = #line) {
        Log.log("\(msg). Session info: [\(logSessionInfo)]", type: level, file: file, function: function, line: line)
    }
    
    private var logSessionInfo: String {
        "\(session.uuid ?? "uuid not avilable"), \(session.name ?? "name not available")"
    }
}
