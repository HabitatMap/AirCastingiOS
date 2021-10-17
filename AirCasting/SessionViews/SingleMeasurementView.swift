// Created by Lunar on 31/08/2021.
//

import SwiftUI
import AirCastingStyling

struct SingleMeasurementView: View {
    @ObservedObject var stream: MeasurementStreamEntity
    var threshold: SensorThreshold?
    @Binding var selectedStream: MeasurementStreamEntity?
    let measurementPresentationStyle: MeasurementPresentationStyle
    let isDormant: Bool
    
    var body: some View {
        VStack(spacing: 3) {
            Text(showStreamName())
                .font(Fonts.SingleMeasurementView.stremName)
                .scaledToFill()
            if measurementPresentationStyle == .showValues,
               let threshold = threshold {
                _SingleMeasurementButton(stream: stream,
                                         value: isDormant ? stream.averageValue : (stream.latestValue ?? 0),
                                         selectedStream: $selectedStream,
                                         threshold: threshold)
            }
        }
    }
    
    func showStreamName() -> String {
        guard let streamName = stream.sensorName else { return "" }
        if streamName == Constants.SensorName.microphone {
            return "dB"
        } else {
            return streamName
                .drop { $0 != "-" }
                .replacingOccurrences(of: "-", with: "")
        }
    }
    
    struct _SingleMeasurementButton: View {
        let stream: MeasurementStreamEntity
        let value: Double
        @Binding var selectedStream: MeasurementStreamEntity?
        @ObservedObject var threshold: SensorThreshold
        
        var body: some View {
            Button(action: {
                selectedStream = stream
            }, label: {
                HStack(spacing: 3) {
                    MeasurementDotView(value: value,
                                       thresholds: threshold)
                    Text("\(Int(value))")
                        .font(Fonts.SingleMeasurementView.value)
                        .scaledToFill()
                }
            })
            .buttonStyle(AirCastingStyling.BorderedButtonStyle(isSelected: selectedStream == stream,
                                                               thresholdColor: threshold.colorFor(value: Int32(value))))
        }
        
    }
}
