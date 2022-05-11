// Created by Lunar on 05/05/2022.
//

import SwiftUI
import AirCastingStyling
import Resolver

class ExternalSessionCardViewModel: ObservableObject {
    @Injected var store: ExternalSessionsStore
    
    func unfollow(sessionUUID: String) {
        store.deleteSession(uuid: sessionUUID) { result in
            switch result {
            case .success():
                Log.info("Unfollowed external session")
            case .failure(let error):
                Log.error("Failure when unfollowing external session \(error)")
            }
        }
    }
}

struct ExternalSessionCard: View {
    var session: ExternalSessionEntity
    let thresholds: [SensorThreshold]
    @State private var isCollapsed: Bool
    @State private var selectedStream: MeasurementStreamEntity?
    @ObservedObject var viewModel = ExternalSessionCardViewModel()
    
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
                    displayButtons()
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
    
    func selectDefaultStreamIfNeeded(streams: [MeasurementStreamEntity]) {
        if selectedStream == nil {
            if let newStream = session.streamWith(sensorName: session.uiState?.sensorName ?? "") {
                return selectedStream = newStream
            }
            selectedStream = streams.first
        }
    }
    
    func displayButtons() -> some View {
        HStack() {
            unFollowButton
            Spacer()
//            mapButton.padding(.trailing, 10)
//            graphButton
        }.padding(.top, 10)
        .buttonStyle(GrayButtonStyle())
    }
    
    private var unFollowButton: some View {
        Button(Strings.SessionCartView.unfollow) {
            viewModel.unfollow(sessionUUID: session.uuid)
        }.buttonStyle(UnFollowButtonStyle())
    }
}

#if DEBUG
struct ExternalSessionCard_Previews: PreviewProvider {
    static var previews: some View {
        ReoredringSessionCard(session: .mock, thresholds: [.mock])
    }
}
#endif
