// Created by Lunar on 22/02/2022.
//
// Created by Lunar on 28/01/2022.
//

import SwiftUI
import AirCastingStyling

struct CompleteScreen: View {
    var session: SearchSession
    let thresholds: [SensorThreshold]
    @State var selectedStream: SearchSession.SearchSessionStream
    
    var body: some View {
        sessionCard
    }
    
    var sessionCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            measurements
            GoogleMapView(pathPoints: [], placePickerIsUpdating: Binding.constant(false), isUserInteracting: Binding.constant(true), mapNotes: .constant([]))
                .frame(height: 300)
                .padding(.vertical)
            buttons
            confirmationButton
        }
        .font(Fonts.regularHeading4)
        .foregroundColor(.aircastingGray)
        .padding()
        .background(
            Group {
                Color.white
                    .shadow(color: .sessionCardShadow, radius: 9, x: 0, y: 1)
            }
        )
    }
}

private extension CompleteScreen {
    var header: some View {
        SearchCompleteScreenHeader(session: session)
    }
    
    var measurements: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.SessionCart.lastMinuteMeasurement)
                .font(Fonts.moderateTitle1)
                .padding(.bottom, 3)
            if let sortedStreams = session.sortedStreams {
                HStack {
                    sortedStreams.count != 1 ? Spacer() : nil
                    ForEach(sortedStreams) { stream in
                        singleMeasurement(stream: stream, value: stream.measurements.last?.value ?? 0, threshold: thresholds.threshold(for: nil))
                        Spacer()
                    }
                }
            }
        }
    }
    
    var buttons: some View {
        HStack {
            Spacer()
            Button {
                //
            } label: {
                Text(Strings.SessionCartView.map)
                    .font(Fonts.semiboldHeading2)
                    .padding(.horizontal, 8)
            }
            Button {
                //
            } label: {
                Text("Chart")
                    .font(Fonts.semiboldHeading2)
                    .padding(.horizontal, 8)
            }
        }
        .buttonStyle(GrayButtonStyle())
    }
    
    var confirmationButton: some View {
        Button {
            //
        } label: {
            Text("Follow Session")
                .font(Fonts.semiboldHeading2)
                .padding(.horizontal, 8)
        }
    }
    
    private func singleMeasurement(stream: SearchSession.SearchSessionStream, value: Double, threshold: SensorThreshold?) -> some View {
        VStack(spacing: 3) {
            Button(action: {
                selectedStream = stream
            }, label: {
                VStack(spacing: 1) {
                    Text(showStreamName(stream: stream))
                        .font(Fonts.systemFont1)
                        .scaledToFill()
                        HStack(spacing: 3) {
                            dot
                            Text("\(Int(value))")
                                .font(Fonts.regularHeading3)
                                .scaledToFill()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder((selectedStream.sensorName == stream.sensorName) ? Color.aircastingGray : .clear)
                        )
                    }
            })
        }
    }
    
    var dot: some View {
        Color.aircastingGray
            .clipShape(Circle())
            .frame(width: 5, height: 5)
    }
    
    func showStreamName(stream: SearchSession.SearchSessionStream) -> String {
        let streamName = stream.sensorName
        if streamName == Constants.SensorName.microphone {
            return Strings.SingleMeasurementView.microphoneUnit
//        } else if stream.isTemperature {
//            return userSettings.convertToCelsius ? Strings.SingleMeasurementView.celsiusUnit : Strings.SingleMeasurementView.fahrenheitUnit
        } else {
            return streamName
                .drop { $0 != "-" }
                .replacingOccurrences(of: "-", with: "")
        }
    }
}

#if DEBUG
struct CompleteScreen_Previews: PreviewProvider {
    static var previews: some View {
        CompleteScreen(session: .mock, thresholds: [.mock], selectedStream: .init(id: 1, sensorPackageName: "AirBeam3", sensorName: "AirBeam-F", measurements: []))
    }
}
#endif
