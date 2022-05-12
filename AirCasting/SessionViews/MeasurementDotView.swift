// Created by Lunar on 28/04/2021.
//

import SwiftUI
import Resolver

struct MeasurementDotView: View {
    
    let value: Double
    @ObservedObject var thresholds: SensorThreshold
    @InjectedObject private var userSettings: UserSettings
    @ObservedObject var stream: MeasurementStreamEntity
    
    var body: some View {
        color
            .clipShape(Circle())
            .frame(width: 5, height: 5)
    }
    
    var color: Color {
        if stream.isTemperature && userSettings.convertToCelsius {
            return thresholds.colorForCelsius(value: Int32(value))
        } else {
            return thresholds.colorFor(value: Int32(value))
        }
    }
}

#if DEBUG
struct MeasurementDotView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementDotView(value: 15.0, thresholds: .mock, stream: MeasurementStreamEntity.mock)
    }
}
#endif
