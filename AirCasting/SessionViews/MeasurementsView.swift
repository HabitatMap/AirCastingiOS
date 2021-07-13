// Created by Lunar on 07/06/2021.
//

import SwiftUI
import AirCastingStyling

struct ABMeasurementsView: View {
    @ObservedObject var session: SessionEntity
    var threshold: SensorThreshold
    @Binding var selectedStream: MeasurementStreamEntity?
    
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
                    Text("Most recefnt measurement:")
                    HStack {
                        Group {
                            ForEach(streams) { stream in
                                SingleMeasurementView(stream: stream,
                                                      value: stream.latestValue ?? 0,
                                                      threshold: threshold,
                                                      selectedStream: _selectedStream)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Your AirBeam is gathering data.")
                        .font(Font.moderate(size: 14))
                    Text("Measurements will appear in 3 minutes.")
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
    
    var body: some View {
        VStack(spacing: 3) {
            Text(showStreamName())
                .font(Font.system(size: 13))
            
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
