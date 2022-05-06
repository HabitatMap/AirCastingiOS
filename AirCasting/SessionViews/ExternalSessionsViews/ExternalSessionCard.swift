// Created by Lunar on 05/05/2022.
//

import SwiftUI
import AirCastingStyling

struct ExternalSessionCard: View {
    var session: ExternalSessionEntity
    let thresholds: [SensorThreshold]
    
    var streams: [MeasurementStreamEntity] {
        session.measurementStreams
    }
    
    var body: some View {
        sessionCard
    }
    
    var sessionCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            measurements
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

private extension ExternalSessionCard {
    var header: some View {
        ExternalSessionHeader(session: session)
    }
    
    private var measurements: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.SessionCart.lastMinuteMeasurement)
                .font(Fonts.moderateTitle1)
                .padding(.bottom, 3)
            HStack {
                streams.count != 1 ? Spacer() : nil
                ForEach(streams, id : \.id) { stream in
                    if let threshold = thresholds.threshold(for: stream.sensorName ?? "") {
                        SingleMeasurementView(stream: stream,
                                              threshold: threshold,
                                              selectedStream: .constant(nil),
                                              isCollapsed: .constant(true),
                                              measurementPresentationStyle: .showValues,
                                              isDormant: false)
                    }
                    Spacer()
                }
            }
        }
    }
}

#if DEBUG
struct ExternalSessionCard_Previews: PreviewProvider {
    static var previews: some View {
        ReoredringSessionCard(session: .mock, thresholds: [.mock])
    }
}
#endif
