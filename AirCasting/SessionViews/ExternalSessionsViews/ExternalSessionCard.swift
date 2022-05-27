// Created by Lunar on 05/05/2022.
//

import SwiftUI
import AirCastingStyling
import Resolver

class ExternalSessionCardViewModel: ObservableObject {
    @Injected private var store: ExternalSessionsStore

    func unfollowTapped(sessionUUID: SessionUUID) {
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
    @State private var isMapButtonActive = false
    @EnvironmentObject var reorderButton: ReorderButton
    @EnvironmentObject var searchAndFollowButton: SearchAndFollowButton

    @StateObject private var mapStatsDataSource: ConveringStatisticsDataSourceDecorator<MapStatsDataSource>
    @StateObject private var mapStatsViewModel: StatisticsContainerViewModel

    @ObservedObject var viewModel = ExternalSessionCardViewModel()

    @Injected private var uiStateHandler: SessionCardUIStateHandler

    init(session: ExternalSessionEntity, thresholds: [SensorThreshold]) {
        self.session = session
        self.thresholds = thresholds
        self._isCollapsed = .init(initialValue: !(session.uiState?.expandedCard ?? false))
        let mapDataSource = ConveringStatisticsDataSourceDecorator<MapStatsDataSource>(dataSource: MapStatsDataSource(), stream: nil)
        self._mapStatsDataSource = .init(wrappedValue: mapDataSource)
        self._mapStatsViewModel = .init(wrappedValue: ExternalSessionCard.createStatsContainerViewModel(dataSource: mapDataSource))
    }

    var streams: [MeasurementStreamEntity] {
        session.sortedStreams
    }

    var body: some View {
        sessionCard
            .onAppear(perform: { selectDefaultStreamIfNeeded(streams: session.allStreams) })
            .onChange(of: selectedStream, perform: { [weak mapStatsDataSource] newStream in
                mapStatsDataSource?.stream = newStream
                mapStatsDataSource?.dataSource.stream = newStream
                uiStateHandler.changeSelectedStream(sessionUUID: session.uuid, newStream: newStream?.sensorName ?? "")
            })
    }

    var sessionCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
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
                mapNavigationLink
            }
        )
    }
}

private extension ExternalSessionCard {
    var header: some View {
        ExternalSessionHeader(session: session, thresholds: .init(value: thresholds), selectedStream: $selectedStream) {
            withAnimation {
                isCollapsed.toggle()
                uiStateHandler.toggleCardExpanded(sessionUUID: session.uuid)
            }
        }
    }

    func pollutionChart(thresholds: [SensorThreshold]) -> some View {
        return VStack() {
            ChartView(thresholds: .init(value: thresholds), stream: $selectedStream, session: session)
            .foregroundColor(.aircastingGray)
                .font(Fonts.semiboldHeading2)
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
            mapButton
        }.padding(.top, 10)
        .buttonStyle(GrayButtonStyle())
    }

    private var unFollowButton: some View {
        Button(Strings.SessionCartView.unfollow) {
            viewModel.unfollowTapped(sessionUUID: session.uuid)
        }.buttonStyle(UnFollowButtonStyle())
    }

    private var mapButton: some View {
        Button {
            isMapButtonActive = true
            reorderButton.isHidden = true
            searchAndFollowButton.isHidden = true
        } label: {
            Text(Strings.SessionCartView.map)
                .font(Fonts.semiboldHeading2)
                .padding(.horizontal, 8)
        }
    }

    private var mapNavigationLink: some View {
        let mapView = ExternalSessionMapView(session: session, thresholds: ABMeasurementsViewThreshold(value: thresholds), selectedStream: $selectedStream, statsContainerViewModel: mapStatsViewModel)
            .foregroundColor(.aircastingDarkGray)

         return NavigationLink(destination: mapView,
                               isActive: $isMapButtonActive,
                               label: {
                                 EmptyView()
                               })
     }

    private static func createStatsContainerViewModel(dataSource: MeasurementsStatisticsDataSource) -> StatisticsContainerViewModel {
        let computeStatisticsInterval: Double = 60

        let controller = MeasurementsStatisticsController(dataSource: dataSource,
                                                          calculator: StandardStatisticsCalculator(),
                                                          scheduledTimer: ScheduledTimerSetter(),
                                                          desiredStats: MeasurementStatistics.Statistic.allCases,
                                                          computeStatisticsInterval: computeStatisticsInterval)
        let viewModel = StatisticsContainerViewModel(statsInput: controller)
        controller.output = viewModel
        return viewModel
    }
}
