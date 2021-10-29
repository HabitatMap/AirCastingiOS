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
    var value: Double {
        isDormant ? stream.averageValue : (stream.latestValue ?? 0)
    }
    
    var body: some View {
        VStack(spacing: 3) {
            Button(action: {
                withAnimation {
                    isCollapsed ? isCollapsed = false : nil
                }
                selectedStream = stream
            }, label: {
                VStack(spacing: 1) {
                    Text(showStreamName())
                        .font(Fonts.systemFont1)
                        .scaledToFill()
                    if let threshold = threshold, measurementPresentationStyle == .showValues {
                        HStack(spacing: 3) {
                            MeasurementDotView(value: value, thresholds: threshold)
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
            })
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
}
