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
        let formatter = ThresholdFormatter(for: thresholds)
        return formatter.formattedColor(for: value)
    }
}

#if DEBUG
struct MeasurementDotView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementDotView(value: 15.0, thresholds: .mock)
    }
}
#endif
