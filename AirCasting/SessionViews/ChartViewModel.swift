// Created by Lunar on 30/09/2021.
//

import SwiftUI

class ChartViewModel: ObservableObject {
    @Published private var averageValues: [Int]?
    private var lastUpdate: Date?
    private var lastMeasurementTime: Date?
    
    func updateChart(for stream: MeasurementStreamEntity) {
        print(stream.lastMeasurementTime)
    }
}
