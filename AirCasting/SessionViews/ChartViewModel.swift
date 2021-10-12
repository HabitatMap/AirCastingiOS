// Created by Lunar on 30/09/2021.
//

import Foundation
import Charts

final class ChartViewModel: ObservableObject {
    @Published var entries: [ChartDataEntry] = []
    @Published var chartStartTime: Date?
    @Published var chartEndTime: Date?
    
    var stream: MeasurementStreamEntity? {
        didSet {
            generateEntries()
        }
    }
    
    private let session: SessionEntity

    private var timeUnit: TimeInterval {
        session.isMobile ? .minute : .hour
    }
    
    private var mainTimer: Timer?
    private var firstTimer: Timer?
    private let numberOfEntries = Constants.Chart.numberOfEntries
    
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
        }
    }
    
    private func startTimers(_ session: SessionEntity) {
        let timeOfNextAverage = timeOfNextAverage()
        firstTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeOfNextAverage), repeats: false) { [weak self] timer in
            self?.generateEntries()
            self?.startMainTimer()
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
            return lastMeasurementTime.roundedDownToHour
        } else {
            let secondsSinceFullMinuteFromSessionStart = Date().timeIntervalSince(sessionStartTime).truncatingRemainder(dividingBy: timeUnit)
            return Date() - secondsSinceFullMinuteFromSessionStart
        }
    }
    
    private func timeOfNextAverage() -> Double {
        let sessionStartTime = session.startTime!
        
        if session.isFixed {
            return Date().roundedUpToHour.timeIntervalSince(Date())
        } else {
            return timeUnit - Date().timeIntervalSince(sessionStartTime).truncatingRemainder(dividingBy: timeUnit)
        }
    }
    
    private func averagedValue(_ intervalStart: Date, _ intervalEnd: Date) -> Double? {
        guard stream != nil else { return nil }
        let measurements = stream!.getMeasurementsFromTimeRange(intervalStart.roundedDownToSecond, intervalEnd.roundedDownToSecond)
        let values = measurements.map { $0.value }
        return values.isEmpty ? nil : round(values.reduce(0, +) / Double(values.count))
    }
}
