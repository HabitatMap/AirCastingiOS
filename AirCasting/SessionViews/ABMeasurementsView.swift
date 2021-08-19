// Created by Lunar on 07/06/2021.
//

import SwiftUI
import AirCastingStyling

enum MeasurementPresentationStyle {
    case showValues
    case hideValues
}

struct ABMeasurementsView: View {
    @ObservedObject var session: SessionEntity
    var thresholds: [SensorThreshold]
    @Binding var selectedStream: MeasurementStreamEntity?
    let measurementPresentationStyle: MeasurementPresentationStyle
    
    private var streamsToShow: [MeasurementStreamEntity] {
        return session.sortedStreams ?? []
    }
    
    var body: some View {
        let streams = streamsToShow
        let hasAnyMeasurements = streams.filter { $0.latestValue != nil }.count > 0
        
        return Group {
            if hasAnyMeasurements {
                VStack(alignment: .leading, spacing: 5) {
                    Text(session.isDormant ? Strings.SessionCart.dormantMeasurementsTitle : Strings.SessionCart.measurementsTitle)
                        .font(Font.moderate(size: 12))
                        .padding(.bottom, 3)
                        .padding(.horizontal)
                    HStack {
                        Group {
                            ForEach(streams, id : \.self) { stream in
                                if let threshold = thresholds.threshold(for: stream) {
                                    SingleMeasurementView(stream: stream,
                                                          value: stream.latestValue ?? 0,
                                                          threshold: threshold,
                                                          selectedStream: _selectedStream,
                                                          measurementPresentationStyle: measurementPresentationStyle)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                if session.followedAt != nil {
                    SessionLoadingView()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Parameters:")
                        HStack {
                            Group {
                                ForEach(streams, id : \.self) { stream in
                                    SingleMeasurementView(stream: stream,
                                                          value: nil,
                                                          threshold: nil,
                                                          selectedStream: .constant(nil),
                                                          measurementPresentationStyle: .hideValues)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
}

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
            if measurementPresentationStyle == .showValues {
                Button(action: {
                    selectedStream = stream
                }, label: {
                    if let value = value,
                       let threshold = threshold {
                        HStack(spacing: 3) {
                            MeasurementDotView(value: value,
                                               thresholds: threshold)
                            Text("\(Int(value))")
                                .font(Font.moderate(size: 14, weight: .regular))
                        }
                        
                    }
                })
                .buttonStyle(AirCastingStyling.BorderedButtonStyle(isSelected: selectedStream == stream,
                                                                   thresholdColor: colorBorder(stream: stream)))
            }
        }
    }
    
    func showStreamName() -> String {
        guard let streamName = stream.sensorName else { return "" }
        return streamName
            .drop { $0 != "-" }
            .replacingOccurrences(of: "-", with: "")
    }
    
    func colorBorder(stream: MeasurementStreamEntity) -> Color {
        guard let value = value else { return .white }
        guard let threshold = threshold else { return .white }
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
