// Created by Lunar on 29/06/2021.
//

import SwiftUI

struct StreamsView: View {
    
    @Binding var selectedStream: MeasurementStreamEntity?
    @Binding var isCollapsed: Bool
    @ObservedObject var session: SessionEntity
    var thresholds: [SensorThreshold]
    @EnvironmentObject private var microphoneManager: MicrophoneManager
    let measurementPresentationStyle: MeasurementPresentationStyle
    

    var body: some View {
        if session.deviceType == .MIC {
            HStack {
                measurementsMic
                Spacer()
            }
        } else {
            ABMeasurementsView(session: session,
                               isCollapsed: $isCollapsed,
                               thresholds: thresholds,
                               selectedStream: _selectedStream,
                               measurementPresentationStyle: measurementPresentationStyle)
        }
    }
    
    var measurementsMic: some View {
        VStack(alignment: .leading, spacing: 5) {
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
            if let dbStream = session.dbStream {
                if let threshold = thresholds.threshold(for: dbStream) {
                    SingleMeasurementView(stream: dbStream,
                                          value: lastMicMeasurement(),
                                          threshold: threshold,
                                          selectedStream: .constant(dbStream),
                                          measurementPresentationStyle: measurementPresentationStyle)
                }
            }
        }
    }
    
    func lastMicMeasurement() -> Double {
        #warning("Not sure (really not sure, maybe it's ok, just pointing out) this silent unwrap fail is good here.")
        return session.dbStream?.latestValue ?? 0
    }
}

#if DEBUG
struct StreamsWithMeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        StreamsView(selectedStream: .constant(nil),
                    isCollapsed: .constant(true),
                    session: .mock,
                    thresholds: [.mock],
                    measurementPresentationStyle: .showValues)
    }
}
#endif
