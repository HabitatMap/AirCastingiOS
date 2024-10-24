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
    // We are using two variables to distinguish between user selection and default selection.
    @State private var selectedStream: MeasurementStreamEntity?
    @State private var userSelection: MeasurementStreamEntity?
    @State private var isMapButtonActive = false
    @State private var isGraphButtonActive = false
    @State private var showLoadingIndicator = false
    @ObservedObject var session: SessionEntity
    @EnvironmentObject var selectedSection: SelectedSection
    @EnvironmentObject private var tabSelection: TabBarSelector
    @EnvironmentObject var reorderButton: ReorderButton
    @EnvironmentObject var searchAndFollowButton: SearchAndFollowButton
    let sessionCartViewModel: SessionCardViewModel
    let thresholds: [SensorThreshold]

    @StateObject private var mapStatsDataSource: ConveringStatisticsDataSourceDecorator<MapStatsDataSource>
    @StateObject private var mapStatsViewModel: StatisticsContainerViewModel
    @StateObject private var graphStatsDataSource: ConveringStatisticsDataSourceDecorator<GraphStatsDataSource>
    @StateObject private var graphStatsViewModel: StatisticsContainerViewModel
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel
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
        let shouldHide = isCollapsed && ( (session.isFixed && selectedSection.section == .fixed) || session.isDormant)
        return shouldHide ? .hideValues : .showValues
    }

    var showChart: Bool {
        (session.isMobile && session.isActive) || (session.isFixed && selectedSection.section == .following)
    }

    var body: some View {
        if session.isInStandaloneMode {
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
        })
        .onChange(of: userSelection, perform: { selection in
            selectedStream = selection
            uiState.changeSelectedStream(sessionUUID: session.uuid, newStream: selection?.sensorName ?? "")
        })
        .onChange(of: isMapButtonActive) { _ in
            reorderButton.setHidden(if: isMapButtonActive)
            searchAndFollowButton.setHidden(if: isMapButtonActive)
        }
        .onChange(of: isGraphButtonActive) { _ in
            reorderButton.setHidden(if: isGraphButtonActive)
            searchAndFollowButton.setHidden(if: isGraphButtonActive)
        }
        .onReceive(tabSelection.dashboardSelectionNotifier, perform: { _ in
            isMapButtonActive = false
            isGraphButtonActive = false
        })
        .font(Fonts.moderateRegularHeading4)
        .foregroundColor(.aircastingGray)
        .padding()
        .background(
            Group {
                Color.aircastingBackground
                    .cardShadow()
                mapNavigationLink
                graphNavigationLink
                // SwiftUI bug: two navigation links don't work properly
                NavigationLink(destination: EmptyView(), label: {EmptyView()})
            }
        )
    }

    var standaloneSessionCard: some View {
        if featureFlagsViewModel.enabledFeatures.contains(.standaloneMode) {
            return AnyView(StandaloneSessionCardView(session: session))
        }
        return AnyView(ReconnectSessionCardView(viewModel: .init(session: session)))
    }

    private func selectDefaultStreamIfNeeded(streams: [MeasurementStreamEntity]) {
        if let stream = streams.first(where: { $0.sensorName == session.userInterface?.sensorName }) {
            selectedStream = stream
        } else if let defaultStream = session.defaultStreamSelection(), let stream = streams.first(where: { $0.sensorName == defaultStream.sensorName }) {
            selectedStream = stream
        } else {
            selectedStream = streams.first
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
                            selectedStream: .init( get: { selectedStream },
                                                   set: { userSelection = $0 }),
                            thresholds: .init(value: thresholds),
                            measurementPresentationStyle: shouldShowValues)
    }

    private var graphButton: some View {
        Button {
            isGraphButtonActive = true
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
            computeStatisticsInterval = 0.25
        } else if session.isFollowed {
            computeStatisticsInterval = 60
        }

        let controller = MeasurementsStatisticsController(dataSource: dataSource,
                                                          calculator: StandardStatisticsCalculator(),
                                                          desiredStats: MeasurementStatistics.Statistic.allCases,
                                                          computeStatisticsInterval: computeStatisticsInterval)
        let viewModel = StatisticsContainerViewModel(statsInput: controller)
        controller.output = viewModel
        return viewModel
    }

    private var mapNavigationLink: some View {
         let mapView = SessionMapView(session: session,
                                  thresholds: .init(value: thresholds),
                                  statsContainerViewModel: _mapStatsViewModel,
                                  statsDataSource: mapStatsDataSource.dataSource,
                                  showLoadingIndicator: $showLoadingIndicator,
                                  selectedStream: $selectedStream)
            .foregroundColor(.aircastingDarkGray)
            .onDisappear { isMapButtonActive = false }

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
             .onDisappear { isGraphButtonActive = false }

         return NavigationLink(destination: graphView,
                               isActive: $isGraphButtonActive,
                               label: {
                                 EmptyView()
                               })
     }
}

// Extension for selecting Stream PM2.5 as default one.
extension SessionEntity {
    func defaultStreamSelection() -> MeasurementStreamEntity? {
        allStreams.first { stream in
            guard let name = stream.sensorName else { return false }
            return name.contains("PM2.5")
         }
    }
}
