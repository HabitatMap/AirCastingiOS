// Created by Lunar on 05/05/2022.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct ExternalSessionCard: View {
    var session: ExternalSessionEntity
    let thresholds: [SensorThreshold]
    @State private var isCollapsed: Bool
    @State private var selectedStream: MeasurementStreamEntity?
    
    @Injected private var uiStateHandler: SessionCardUIStateHandler
    
    init(session: ExternalSessionEntity, thresholds: [SensorThreshold]) {
        self.session = session
        self.thresholds = thresholds
        self._isCollapsed = .init(initialValue: !(session.uiState?.expandedCard ?? false))
    }
    
    var streams: [MeasurementStreamEntity] {
        session.measurementStreams
    }
    
    var body: some View {
        sessionCard
            .onAppear(perform: { selectDefaultStreamIfNeeded(streams: session.measurementStreams) })
    }
    
    var sessionCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            measurements
            VStack(alignment: .trailing, spacing: 10) {
                if !isCollapsed {
                    pollutionChart(thresholds: thresholds)
//                    displayButtons(thresholds: thresholds)
                }
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

private extension ExternalSessionCard {
    var header: some View {
        ExternalSessionHeader(session: session) {
            withAnimation {
                isCollapsed.toggle()
                // TODO: Handle toggling uiState for external session
                //uiStateHandler.toggleCardExpanded(sessionUUID: SessionUUID(stringLiteral: session.uuid))
            }
        }
    }
    
    func pollutionChart(thresholds: [SensorThreshold]) -> some View {
        return VStack() {
            ChartView(thresholds: thresholds, stream: $selectedStream, session: ChartViewModel.Session.externalSession(session))
            .foregroundColor(.aircastingGray)
                .font(Fonts.semiboldHeading2)
        }
    }
    
    private var measurements: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.SessionCart.lastMinuteMeasurement)
                .font(Fonts.moderateTitle1)
                .padding(.bottom, 3)
            HStack {
                streams.count != 1 ? Spacer() : nil
                ForEach(streams, id : \.id) { stream in
//                    if let threshold = thresholds.threshold(for: stream.sensorName ?? "") {
                    if let threshold = thresholds.threshold(for: "PM2.5") { // This is temporary until we start saving thresholds
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
    
    func selectDefaultStreamIfNeeded(streams: [MeasurementStreamEntity]) {
        if selectedStream == nil {
            if let newStream = session.streamWith(sensorName: session.uiState?.sensorName ?? "") {
                return selectedStream = newStream
            }
            selectedStream = streams.first
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
