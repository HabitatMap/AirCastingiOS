//
//  SessionCell.swift
//  AirCasting
//
//  Created by Lunar on 08/01/2021.
//
import AirCastingStyling
import Charts
import SwiftUI
import Resolver

struct SessionCardView: View {
    @State private var isCollapsed: Bool
    @State private var selectedStream: MeasurementStreamEntity?
    @State private var isMapButtonActive = false
    @State private var isGraphButtonActive = false
    @State private var showLoadingIndicator = false
    @ObservedObject var session: SessionEntity
    @EnvironmentObject var selectedSection: SelectSection
    @EnvironmentObject var reorderButton: ReorderButton
    @EnvironmentObject var searchAndFollowButton: SearchAndFollowButton
    let sessionCartViewModel: SessionCardViewModel
    let thresholds: [SensorThreshold]

    @StateObject private var mapStatsDataSource: ConveringStatisticsDataSourceDecorator<MapStatsDataSource>
    @StateObject private var mapStatsViewModel: StatisticsContainerViewModel
    @StateObject private var graphStatsDataSource: ConveringStatisticsDataSourceDecorator<GraphStatsDataSource>
    @StateObject private var graphStatsViewModel: StatisticsContainerViewModel
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
    @Injected private var measurementStreamStorage: MeasurementStreamStorage
    @Injected private var uiState: SessionCardUIStateHandler

    init(session: SessionEntity,
         sessionCartViewModel: SessionCardViewModel,
         thresholds: [SensorThreshold]) {
        self.session = session
        self.sessionCartViewModel = sessionCartViewModel
        self.thresholds = thresholds

        self._isCollapsed = .init(initialValue: !(session.userInterface?.expandedCard ?? false))

        let mapDataSource = ConveringStatisticsDataSourceDecorator<MapStatsDataSource>(dataSource: MapStatsDataSource(), stream: nil)
        self._mapStatsDataSource = .init(wrappedValue: mapDataSource)
        self._mapStatsViewModel = .init(wrappedValue: SessionCardView.createStatsContainerViewModel(dataSource: mapDataSource, session: session))
        let graphDataSource = ConveringStatisticsDataSourceDecorator<GraphStatsDataSource>(dataSource: GraphStatsDataSource(), stream: nil)
        self._graphStatsDataSource = .init(wrappedValue: graphDataSource)
        self._graphStatsViewModel = .init(wrappedValue: SessionCardView.createStatsContainerViewModel(dataSource: graphDataSource, session: session))
    }

    var shouldShowValues: MeasurementPresentationStyle {
        // We need to specify selectedSection to show values for fixed session only in following tab
        let shouldHide = isCollapsed && ( (session.isFixed && selectedSection.selectedSection == SelectedSection.fixed) || session.isDormant)
        return shouldHide ? .hideValues : .showValues
    }

    var showChart: Bool {
        (session.isMobile && session.isActive) || (session.isFixed && selectedSection.selectedSection == SelectedSection.following)
    }

    var body: some View {
        if session.isInStandaloneMode && featureFlagsViewModel.enabledFeatures.contains(.standaloneMode) {
            standaloneSessionCard
        } else {
            sessionCard
        }
    }

    var sessionCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            measurements
            VStack(alignment: .trailing, spacing: 10) {
                if !isCollapsed {
                    showChart ? pollutionChart(thresholds: thresholds) : nil
                    displayButtons()
                }
            }
        }
        .onAppear {
            selectDefaultStreamIfNeeded(streams: session.sortedStreams)
        }
        .onChange(of: session.sortedStreams) { newValue in
            selectDefaultStreamIfNeeded(streams: newValue)
        }
        .onChange(of: selectedStream, perform: { [weak graphStatsDataSource, weak mapStatsDataSource] newStream in
            graphStatsDataSource?.stream = newStream
            graphStatsDataSource?.dataSource.stream = newStream
            mapStatsDataSource?.stream = newStream
            mapStatsDataSource?.dataSource.stream = newStream
            uiState.changeSelectedStream(sessionUUID: session.uuid, newStream: newStream?.sensorName ?? "")
        })
        .onChange(of: isMapButtonActive) { _ in
            reorderButton.setHidden(if: isMapButtonActive)
            searchAndFollowButton.setHidden(if: isMapButtonActive)
        }
        .onChange(of: isGraphButtonActive) { _ in
            reorderButton.setHidden(if: isGraphButtonActive)
            searchAndFollowButton.setHidden(if: isGraphButtonActive)
        }
        .font(Fonts.moderateRegularHeading4)
        .foregroundColor(.aircastingGray)
        .padding()
        .background(
            Group {
                Color.white
                    .cardShadow()
                mapNavigationLink
                graphNavigationLink
                // SwiftUI bug: two navigation links don't work properly
                NavigationLink(destination: EmptyView(), label: {EmptyView()})
            }
        )
    }

    var standaloneSessionCard: some View {
        StandaloneSessionCardView(session: session)
    }

    private func selectDefaultStreamIfNeeded(streams: [MeasurementStreamEntity]) {
        if selectedStream == nil {
            if let newStream = session.streamWith(sensorName: session.userInterface?.sensorName ?? "") {
                return selectedStream = newStream
            }
            selectedStream = session.defaultStreamSelection() ?? streams.first
        }
    }
}

private extension SessionCardView {
    var header: some View {
        SessionHeaderView(
            action: {
                withAnimation {
                    isCollapsed.toggle()
                    if !session.isUnfollowedFixed {
                        uiState.toggleCardExpanded(sessionUUID: session.uuid)
                    }
                }
            },
            isExpandButtonNeeded: true,
            isCollapsed: $isCollapsed,
            session: session
        )
    }

    private var measurements: some View {
        _ABMeasurementsView(measurementsViewModel: DefaultSyncingMeasurementsViewModel(sessionDownloader: SessionDownloadService(), session: session),
                            session: session,
                            isCollapsed: $isCollapsed,
                            selectedStream: $selectedStream,
                            thresholds: .init(value: thresholds),
                            measurementPresentationStyle: shouldShowValues)
    }

    private var graphButton: some View {
        Button {
            isGraphButtonActive = true
            Log.info("\(reorderButton)")
        } label: {
            Text(Strings.SessionCartView.graph)
                .font(Fonts.muliSemiboldHeading2)
                .padding(.horizontal, 8)
        }
    }

    private var mapButton: some View {
        Button {
            isMapButtonActive = true
        } label: {
            Text(Strings.SessionCartView.map)
                .font(Fonts.muliSemiboldHeading2)
                .padding(.horizontal, 8)
        }
    }

    private var followButton: some View {
        Button(Strings.SessionCartView.follow) {
            sessionCartViewModel.toggleFollowing()
        }.buttonStyle(FollowButtonStyle())
    }

    private var unFollowButton: some View {
        Button(Strings.SessionCartView.unfollow) {
            sessionCartViewModel.toggleFollowing()
        }.buttonStyle(UnFollowButtonStyle())
    }

    func pollutionChart(thresholds: [SensorThreshold]) -> some View {
        VStack() {
            ChartView(thresholds: .init(value: thresholds), stream: $selectedStream, session: session)
                .foregroundColor(.aircastingGray)
                .font(Fonts.muliSemiboldHeading2)
        }
    }

    func displayButtons() -> some View {
        HStack() {
            if sessionCartViewModel.isFollowing && session.type == .fixed {
                unFollowButton
            } else if session.type == .fixed {
                followButton
            }
            Spacer()
            !(session.isIndoor || session.locationless) ? mapButton.padding(.trailing, 5) : nil
            graphButton
        }.padding(.top, 10)
        .buttonStyle(GrayButtonStyle())
    }

    private static func createStatsContainerViewModel(dataSource: MeasurementsStatisticsDataSource, session: SessionEntity) -> StatisticsContainerViewModel {
        var computeStatisticsInterval: Double? = nil

        if session.isActive || session.isNew {
            computeStatisticsInterval = 1
        } else if session.isFollowed {
            computeStatisticsInterval = 60
        }

        let controller = MeasurementsStatisticsController(dataSource: dataSource,
                                                          calculator: StandardStatisticsCalculator(),
                                                          scheduledTimer: ScheduledTimerSetter(),
                                                          desiredStats: MeasurementStatistics.Statistic.allCases,
                                                          computeStatisticsInterval: computeStatisticsInterval)
        let viewModel = StatisticsContainerViewModel(statsInput: controller)
        controller.output = viewModel
        return viewModel
    }

    private var mapNavigationLink: some View {
         let mapView = AirMapView(session: session,
                                  thresholds: .init(value: thresholds),
                                  statsContainerViewModel: _mapStatsViewModel,
                                  showLoadingIndicator: $showLoadingIndicator,
                                  selectedStream: $selectedStream)
            .foregroundColor(.aircastingDarkGray)

         return NavigationLink(destination: mapView,
                               isActive: $isMapButtonActive,
                               label: {
                                 EmptyView()
                               })
     }

     private var graphNavigationLink: some View {
         let graphView = GraphView(session: session,
                                   thresholds: thresholds,
                                   selectedStream: $selectedStream,
                                   statsContainerViewModel: graphStatsViewModel,
                                   graphStatsDataSource: graphStatsDataSource.dataSource)
             .foregroundColor(.aircastingDarkGray)

         return NavigationLink(destination: graphView,
                               isActive: $isGraphButtonActive,
                               label: {
                                 EmptyView()
                               })
     }
}
