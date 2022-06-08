// Created by Lunar on 28/04/2021.
//

import SwiftUI
import Resolver

struct MeasurementDotView: View {
    let value: Double
    @ObservedObject var thresholds: SensorThreshold
    var body: some View {
        color
            .clipShape(Circle())
            .frame(width: 5, height: 5)
    }
    
    var color: Color {
        let formatter = Resolver.resolve(ThresholdFormatter.self, args: thresholds)
        return formatter.color(for: value)
    }
}
