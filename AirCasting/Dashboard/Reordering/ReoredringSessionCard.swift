// Created by Lunar on 28/01/2022.
//

import SwiftUI
import AirCastingStyling

struct ReoredringSessionCard: View {
    @ObservedObject var session: SessionEntity
    let thresholds: [SensorThreshold]
    
    var hasStreams: Bool {
        session.allStreams != nil && session.allStreams != []
    }
    
    var body: some View {
        sessionCard
    }
    
    var sessionCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            if hasStreams {
                measurements
            } else {
                SessionLoadingView()
            }
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

private extension ReoredringSessionCard {
    var header: some View {
        ReorderingSessionHeader(session: session)
    }
    
    private var measurements: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.SessionCart.lastMinuteMeasurement)
                .font(Fonts.moderateTitle1)
                .padding(.bottom, 3)
            HStack {
                session.sortedStreams!.count != 1 ? Spacer() : nil
                ForEach(session.sortedStreams!.filter({ !$0.gotDeleted }), id : \.self) { stream in
                    if let threshold = thresholds.threshold(for: stream.sensorName ?? "") {
                        SingleMeasurementView(stream: stream,
                                              threshold: .init(value: threshold),
                                              selectedStream: .constant(nil),
                                              isCollapsed: .constant(true),
                                              measurementPresentationStyle: .showValues,
                                              isDormant: session.isDormant)
                    }
                    Spacer()
                }
            }
        }
    }
}

#if DEBUG
struct ReoredringSessionCard_Previews: PreviewProvider {
    static var previews: some View {
        ReoredringSessionCard(session: .mock, thresholds: [.mock])
    }
}
#endif
