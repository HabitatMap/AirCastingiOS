// Created by Lunar on 30/09/2021.
//

import Foundation
import Charts

final class ChartViewModel: ObservableObject {
    @Published var entries: [ChartDataEntry] = []
    
    private let stream: MeasurementStreamEntity

    private var timeUnit: Double {
        stream.session.type == .mobile ? TimeInterval.minute : TimeInterval.hour
    }
    let formatter = DateFormatter()
    
    private var mainTimer: Timer?
    private var firstTimer: Timer?
    private let numberOfEntries: Int
    
    deinit {
        mainTimer?.invalidate()
        firstTimer?.invalidate()
    }
    
    init(stream: MeasurementStreamEntity, numberOfEntries: Int) {
        formatter.dateFormat = "HH:mm:ss.SSSS"
        self.stream = stream
        self.numberOfEntries = numberOfEntries
        generateEntries()
        startTimers(stream.session)
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
    
    private func generateEntries() {
        // Set up begning and end of the interval for the first average
        //  - for fixed sessions we are taking the last full hour of the session, which has any measurements
        //  - for mobile we are taking into account full minutes since the session started and we are taking the most recent one
        guard var intervalEnd = intervalEndTime() else {
            return
        }
        
        var intervalStart = intervalEnd - timeUnit
        
        var entries = [ChartDataEntry]()
        
        for i in (0..<numberOfEntries).reversed() {
            if (intervalStart < stream.session.startTime!.roundedDownToSecond) { break }
            let average = averagedValue(intervalStart, intervalEnd)
            if let average = average {
                entries.append(ChartDataEntry(x: Double(i), y: average))
            }
            intervalEnd = intervalStart
            intervalStart = intervalEnd - timeUnit
        }
        
        self.entries = entries
    }
    
    private func intervalEndTime() -> Date? {
        guard let lastMeasurementTime = stream.lastMeasurementTime else { return nil }
        let sessionStartTime = stream.session.startTime!
        
        if stream.session.isFixed {
            return lastMeasurementTime.roundedDownToHour
        } else {
            let secondsSinceFullMinuteFromSessionStart = Date().timeIntervalSince(sessionStartTime).truncatingRemainder(dividingBy: timeUnit)
            return Date() - secondsSinceFullMinuteFromSessionStart
        }
    }
    
    private func timeOfNextAverage() -> Double {
        let sessionStartTime = stream.session.startTime!
        
        if stream.session.isFixed {
            return Date().roundedUpToHour.timeIntervalSince(Date())
        } else {
            return timeUnit - Date().timeIntervalSince(sessionStartTime).truncatingRemainder(dividingBy: timeUnit)
        }
    }
    
    private func averagedValue(_ intervalStart: Date, _ intervalEnd: Date) -> Double? {
        let measurements = stream.getMeasurementsFromTimeRange(intervalStart.roundedDownToSecond, intervalEnd.roundedDownToSecond)
        let values = measurements.map { $0.value}
        return values.isEmpty ? nil : round(values.reduce(0, +) / Double(values.count))
    }
}
