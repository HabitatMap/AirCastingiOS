// Created by Lunar on 31/08/2021.
//

import SwiftUI
import AirCastingStyling

struct SingleMeasurementView: View {
    @ObservedObject var stream: MeasurementStreamEntity
    var threshold: SensorThreshold?
    @Binding var selectedStream: MeasurementStreamEntity?
    @Binding var isCollapsed: Bool
    let measurementPresentationStyle: MeasurementPresentationStyle
    let isDormant: Bool
    
    var body: some View {
        VStack(spacing: 3) {
            if let threshold = threshold {
                _SingleMeasurementButton(stream: stream,
                                         value: isDormant ? stream.averageValue : (stream.latestValue ?? 0),
                                         streamName: showStreamName(),
                                         shouldShow: measurementPresentationStyle == .showValues,
                                         selectedStream: $selectedStream,
                                         isCollapsed: $isCollapsed,
                                         threshold: threshold
                )
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
        let streamName: String
        let shouldShow: Bool
        @Binding var selectedStream: MeasurementStreamEntity?
        @Binding var isCollapsed: Bool
        @ObservedObject var threshold: SensorThreshold
        
        var body: some View {
            Button(action: {
                withAnimation {
                    isCollapsed ? isCollapsed = false : nil
                }
                selectedStream = stream
            }, label: {
                VStack(spacing: 1) {
                    Text(streamName)
                        .font(Fonts.systemFont1)
                        .scaledToFill()
                    if shouldShow {
                        measurementDotView
                    }
                }
            })
        }
        
        var measurementDotView: some View {
            HStack(spacing: 3) {
                MeasurementDotView(value: value,
                                   thresholds: threshold)
                Text("\(Int(value))")
                    .font(Fonts.regularHeading3)
                    .scaledToFill()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 9)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder((selectedStream == stream) ? threshold.colorFor(value: Int32(value)) : .clear)
            )
        }
    }
}
