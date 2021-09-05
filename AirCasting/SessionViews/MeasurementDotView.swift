// Created by Lunar on 28/04/2021.
//

import SwiftUI

struct MeasurementDotView: View {
    
    let value: Double
    @ObservedObject var thresholds: SensorThreshold
    
    var body: some View {
        color
            .clipShape(Circle())
            .frame(width: 5, height: 5)
    }
    
    var color: Color {
        switch Int32(value) {
        case thresholds.thresholdVeryLow ..< thresholds.thresholdLow:
            return Color.aircastingGreen
        case thresholds.thresholdLow ..< thresholds.thresholdMedium:
            return Color.aircastingYellow
        case thresholds.thresholdMedium ..< thresholds.thresholdHigh :
            return Color.aircastingOrange
        case thresholds.thresholdHigh ... thresholds.thresholdVeryHigh :
            return Color.aircastingRed
        default:
            return Color.aircastingGray
        }
    }
}

#if DEBUG
struct MeasurementDotView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementDotView(value: 15.0, thresholds: .mock)
    }
}
#endif
