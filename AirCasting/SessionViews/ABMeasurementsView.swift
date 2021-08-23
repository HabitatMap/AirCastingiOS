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
    @Binding var isCollapsed: Bool
    var thresholds: [SensorThreshold]
    @EnvironmentObject var selectedSection: SelectSection
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
                    if session.type == .mobile {
                        if !session.isDormant {
                            Text(Strings.SessionCart.measurementsTitle)
                                .font(Font.moderate(size: 12))
                                .padding(.bottom, 3)
                        } else {
                            if isCollapsed {
                                Text(Strings.SessionCart.parametersText)
                                    .font(Font.moderate(size: 12))
                                    .padding(.bottom, 3)
                            } else {
                                Text(Strings.SessionCart.dormantMeasurementsTitle)
                                    .font(Font.moderate(size: 12))
                                    .padding(.bottom, 3)
                            }
                        }
                    } else if selectedSection.selectedSection == .fixed {
                        if isCollapsed {
                            Text(Strings.SessionCart.parametersText)
                                .font(Font.moderate(size: 12))
                                .padding(.bottom, 3)
                        } else {
                            Text(Strings.SessionCart.lastMinuteMeasurement)
                                .font(Font.moderate(size: 12))
                                .padding(.bottom, 3)
                        }
                    } else {
                            Text(Strings.SessionCart.lastMinuteMeasurement)
                                .font(Font.moderate(size: 12))
                                .padding(.bottom, 3)
                    }
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
                        }.padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                if session.followedAt != nil {
                    SessionLoadingView()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Strings.SessionCart.parametersText)
                        HStack {
                            Group {
                                ForEach(streams, id : \.self) { stream in
                                    SingleMeasurementView(stream: stream,
                                                          value: nil,
                                                          threshold: nil,
                                                          selectedStream: .constant(nil),
                                                          measurementPresentationStyle: .hideValues)
                                }
                            }.padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
        if streamName == Constants.SensorName.microphone {
              return "db"
        } else {
            return streamName
                .drop { $0 != "-" }
                .replacingOccurrences(of: "-", with: "")
        }
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
