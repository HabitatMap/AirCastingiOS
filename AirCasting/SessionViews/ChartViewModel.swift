// Created by Lunar on 30/09/2021.
//

import Foundation
import Charts

final class ChartViewModel: ObservableObject {
    @Published var entries: [ChartDataEntry] = []
    
    private let stream: MeasurementStreamEntity

    private var timeUnit: Double {
        stream.session.type == .mobile ? 60 : 60*60
    }
    
    private var mainTimer: Timer?
    private var firstTimer: Timer?
    
    deinit {
        mainTimer?.invalidate()
        firstTimer?.invalidate()
    }
    
    init(stream: MeasurementStreamEntity) {
        self.stream = stream
        generateEntries()
        startTimers(stream.session)
    }
    
    private func startTimers(_ session: SessionEntity) {
        let sessionStartTime = session.startTime!
        let secondsUntilFullMinute = timeUnit - Double(Int(Date().timeIntervalSince(sessionStartTime)) % Int(timeUnit))

        firstTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(secondsUntilFullMinute), repeats: false) { [weak self] timer in
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
        var intervalEnd = Date()
        var intervalStart = intervalEnd - timeUnit
        
        var entries = [ChartDataEntry]()
        
        for i in (0...8).reversed() {
            if (intervalStart < stream.session.startTime!) { break }
            let average = averagedValue(intervalStart, intervalEnd)
            if let average = average {
                entries.append(ChartDataEntry(x: Double(i), y: average))
            }
            intervalEnd = intervalStart
            intervalStart = intervalEnd - timeUnit
        }
        
        self.entries = entries
    }
    
    private func averagedValue(_ intervalStart: Date, _ intervalEnd: Date) -> Double? {
        let measurements = stream.getMeasurementsFromTimeRange(intervalStart.roundedToSecond, intervalEnd.roundedToSecond)
        let values = measurements.map { $0.value}
        return values.isEmpty ? nil : round(values.reduce(0, +)/Double(values.count))
    }
}
