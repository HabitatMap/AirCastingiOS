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
        let allStreams = [session.pm1Stream,
                          session.pm2Stream,
                          session.pm10Stream,
                          session.FStream,
                          session.HStream]
        
        let toShow = allStreams.compactMap { $0 }
        return toShow
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
                            ForEach(streams, id : \.self) {
                                SingleMeasurementView(stream: $0,
                                                      value: session.isDormant ? $0.averageValue : ($0.latestValue ?? 0),
                                                      threshold: threshold,
                                                      selectedStream: _selectedStream,
                                                      measurementPresentationStyle: measurementPresentationStyle)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Strings.LoadingSession.title)
                        .font(Font.moderate(size: 14))
                    Text(Strings.LoadingSession.description)
                        .font(Font.moderate(size: 12))
                }
                .foregroundColor(.darkBlue)
            }
        }
    }
}

struct SingleMeasurementView: View {
    let stream: MeasurementStreamEntity
    let value: Double
    var threshold: SensorThreshold
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
                    HStack(spacing: 3) {
                        MeasurementDotView(value: value,
                                           thresholds: threshold)
                        Text("\(Int(value))")
                            .font(Font.moderate(size: 14, weight: .regular))
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
