// Created by Lunar on 31/08/2021.
//

import SwiftUI
import AirCastingStyling

struct SingleMeasurementView: View {
    let stream: MeasurementStreamEntity
    let value: Double?
    var threshold: SensorThreshold?
    @Binding var selectedStream: MeasurementStreamEntity?
    let measurementPresentationStyle: MeasurementPresentationStyle
    
    var body: some View {
        VStack(spacing: 3) {
            Text(showStreamName())
                .font(Font.system(size: 13))
                .scaledToFill()
            if measurementPresentationStyle == .showValues,
               let value = value,
               let threshold = threshold {
                _SingleMeasurementButton(stream: stream,
                                         value: value,
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
                        .font(Font.moderate(size: 14, weight: .regular))
                        .scaledToFill()
                }
            })
            .buttonStyle(AirCastingStyling.BorderedButtonStyle(isSelected: selectedStream == stream,
                                                               thresholdColor: colorBorder(stream: stream)))
        }
        
        func colorBorder(stream: MeasurementStreamEntity) -> Color {
            switch Int32(value) {
            case threshold.thresholdVeryLow..<threshold.thresholdLow:
                return .aircastingGreen
            case threshold.thresholdLow..<threshold.thresholdMedium:
                return .aircastingYellow
            case threshold.thresholdMedium..<threshold.thresholdHigh:
                return .aircastingOrange
            case threshold.thresholdHigh..<threshold.thresholdVeryHigh:
                return .aircastingRed
            default:
                return .white
            }
        }
    }
}
