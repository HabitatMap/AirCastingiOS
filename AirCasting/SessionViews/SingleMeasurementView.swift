// Created by Lunar on 31/08/2021.
//

import SwiftUI
import AirCastingStyling
import Resolver

class SingleMeasurementViewThreshold: ObservableObject {
    var value: SensorThreshold?
    
    init(value: SensorThreshold? = nil) {
        self.value = value
    }
}

struct SingleMeasurementView: View {
    @ObservedObject var stream: MeasurementStreamEntity
    @ObservedObject var threshold: SingleMeasurementViewThreshold
    @Binding var selectedStream: MeasurementStreamEntity?
    @Binding var isCollapsed: Bool
    @InjectedObject private var userSettings: UserSettings
    let measurementPresentationStyle: MeasurementPresentationStyle
    let isDormant: Bool
    var value: Double? {
        guard let measurementValue = isDormant ? stream.averageValue : stream.latestValue else {
            return nil
        }
        
        guard !(stream.isTemperature && userSettings.convertToCelsius) else {
            return TemperatureConverter.calculateCelsius(fahrenheit: measurementValue)
        }
        
        return measurementValue
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
                        .font(Fonts.systemFontRegularHeading1)
                        .scaledToFill()
                    if let threshold = threshold.value, measurementPresentationStyle == .showValues {
                        let formatter = Resolver.resolve(ThresholdFormatter.self, args: threshold)
                        HStack(spacing: 3) {
                            if value != nil {
                                MeasurementDotView(value: value!, thresholds: threshold)
                                Text("\(Int(value!))")
                                    .font(Fonts.moderateRegularHeading3)
                                    .scaledToFill()
                            } else {
                                Text("-")
                                    .font(Fonts.moderateRegularHeading3)
                                    .scaledToFill()
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder((selectedStream == stream && value != nil) ? formatter.color(for: value!) : .clear)
                        )
                    }
                }
            })
        }
    }
    
    func showStreamName() -> String {
        guard let streamName = stream.sensorName else { return "" }
        if streamName == Constants.SensorName.microphone {
            return Strings.SingleMeasurementView.microphoneUnit
        } else if stream.isTemperature {
            return userSettings.convertToCelsius ? Strings.SingleMeasurementView.celsiusUnit : Strings.SingleMeasurementView.fahrenheitUnit
        } else {
            return streamName
                .drop { $0 != "-" }
                .replacingOccurrences(of: "-", with: "")
        }
    }
}
