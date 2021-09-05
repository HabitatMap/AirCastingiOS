//
//  SessionCell.swift
//  AirCasting
//
//  Created by Lunar on 08/01/2021.
//

import AirCastingStyling
import Charts
import CoreData
import CoreLocation
import SwiftUI

struct SessionCartView: View {
    @State private var isCollapsed = true
    @State private var selectedStream: MeasurementStreamEntity?
    @State private var isMapButtonActive = false
    @State private var isGraphButtonActive = false
    @ObservedObject var session: SessionEntity
    let sessionCartViewModel: SessionCartViewModel
    let thresholds: [SensorThreshold]
    let sessionStoppableFactory: SessionStoppableFactory
    private let locationTracker: LocationTracker
    @StateObject private var mapStatsDataSource: MapStatsDataSource
    @StateObject private var mapStatsViewModel: StatisticsContainerViewModel
    @StateObject private var graphStatsDataSource: GraphStatsDataSource
    @StateObject private var graphStatsViewModel: StatisticsContainerViewModel
    
    init(session: SessionEntity,
         sessionCartViewModel: SessionCartViewModel,
         thresholds: [SensorThreshold],
         sessionStoppableFactory: SessionStoppableFactory,
         locationTracker: LocationTracker) {
        self.session = session
        self.sessionCartViewModel = sessionCartViewModel
        self.thresholds = thresholds
        self.sessionStoppableFactory = sessionStoppableFactory
        self.locationTracker = locationTracker
        let mapDataSource = MapStatsDataSource()
        self._mapStatsDataSource = .init(wrappedValue: mapDataSource)
        self._mapStatsViewModel = .init(wrappedValue: SessionCartView.createStatsContainerViewModel(dataSource: mapDataSource))
        let graphDataSource = GraphStatsDataSource()
        self._graphStatsDataSource = .init(wrappedValue: graphDataSource)
        self._graphStatsViewModel = .init(wrappedValue: SessionCartView.createStatsContainerViewModel(dataSource: graphDataSource))
    }
    
    var shouldShowValues: MeasurementPresentationStyle {
        let shouldShow = isCollapsed && (session.isFixed || session.isDormant)
        return shouldShow ? .hideValues : .showValues
    }

    var showChart: Bool {
        !isCollapsed && session.type == .mobile && session.status == .RECORDING
    }
    var hasStreams: Bool {
        session.allStreams != nil || session.allStreams != []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            header
            if hasStreams {
                StreamsView(selectedStream: $selectedStream,
                            session: session,
                            thresholds: thresholds,
                            measurementPresentationStyle: shouldShowValues)

                VStack(alignment: .trailing, spacing: 40) {
                    if showChart {
                        pollutionChart(thresholds: thresholds)
                    }
                    if !isCollapsed {
                        displayButtons(thresholds: thresholds)
                    }
                }
            } else {
                SessionLoadingView()
            }
        }
        .onChange(of: session.sortedStreams) { newValue in
            selectDefaultStreamIfNeeded(streams: newValue ?? [])
        }
        .onChange(of: selectedStream, perform: { [weak graphStatsViewModel, weak mapStatsViewModel, weak graphStatsDataSource, weak mapStatsDataSource] newStream in
            graphStatsViewModel?.unit = newStream?.unitSymbol
            mapStatsViewModel?.unit = newStream?.unitSymbol
            graphStatsDataSource?.stream = newStream
            mapStatsDataSource?.stream = newStream
        })
        .onAppear {
            selectDefaultStreamIfNeeded(streams: session.sortedStreams ?? [])
        }
        .font(Font.moderate(size: 13, weight: .regular))
        .foregroundColor(.aircastingGray)
        .padding()
        .background(
            Group {
                Color.white
                    .shadow(color: Color(red: 205/255, green: 209/255, blue: 214/255, opacity: 0.36), radius: 9, x: 0, y: 1)
                mapNavigationLink
                graphNavigationLink
                // SwiftUI bug: two navigation links don't work properly
                NavigationLink(destination: EmptyView(), label: {EmptyView()})
            }
        )
    }
    
    private func selectDefaultStreamIfNeeded(streams: [MeasurementStreamEntity]) {
        if selectedStream == nil {
            selectedStream = streams.first
        }
    }
}

private extension SessionCartView {
    var header: some View {
        SessionHeaderView(
            action: {
                withAnimation {
                    isCollapsed.toggle()
                }
            }, isExpandButtonNeeded: true,
            isCollapsed: $isCollapsed,
            session: session,
            sessionStopperFactory: sessionStoppableFactory
        )
    }
    
    var graphButton: some View {
        Button {
            isGraphButtonActive = true
        } label: {
            Text(Strings.SessionCartView.graph)
                .font(Font.muli(size: 13, weight: .semibold))
                .padding(.horizontal, 8)
        }
    }
    
    var mapButton: some View {
        Button {
            isMapButtonActive = true
        } label: {
            Text(Strings.SessionCartView.map)
                .font(Font.muli(size: 13, weight: .semibold))
                .padding(.horizontal, 8)
        }
    }
    
    var followButton: some View {
        Button(Strings.SessionCartView.follow) {
            sessionCartViewModel.toggleFollowing()
        }.buttonStyle(FollowButtonStyle())
    }
    
    var unFollowButton: some View {
        Button(Strings.SessionCartView.unfollow) {
            sessionCartViewModel.toggleFollowing()
        }.buttonStyle(UnFollowButtonStyle())
    }
    
    var mapNavigationLink: some View {
        let mapView = AirMapView(thresholds: thresholds,
                                 statsContainerViewModel: mapStatsViewModel,
                                 mapStatsDataSource: mapStatsDataSource,
                                 session: session,
                                 selectedStream: $selectedStream,
                                 sessionStoppableFactory: sessionStoppableFactory,
                                 locationTracker: locationTracker)
        
        return NavigationLink(destination: mapView,
                              isActive: $isMapButtonActive,
                              label: {
                                EmptyView()
                              })
    }
    
    var graphNavigationLink: some View {
        let graphView = GraphView(session: session,
                                  thresholds: thresholds,
                                  selectedStream: $selectedStream,
                                  statsContainerViewModel: graphStatsViewModel,
                                  graphStatsDataSource: graphStatsDataSource,
                                  sessionStoppableFactory: sessionStoppableFactory)
        return NavigationLink(destination: graphView,
                              isActive: $isGraphButtonActive,
                              label: {
                                EmptyView()
                              })
    }
    
    func pollutionChart(thresholds: [SensorThreshold]) -> some View {
        Group {
            if let selectedStream = selectedStream {
                ChartView(stream: selectedStream,
                          thresholds: thresholds)
                    .frame(height: 200)
            }
        }
    }
    
    func displayButtons(thresholds: [SensorThreshold]) -> some View {
        HStack(spacing: 20) {
            if sessionCartViewModel.isFollowing && session.type == .fixed {
                unFollowButton
            } else if session.type == .fixed {
                followButton
            }
            Spacer()
            if !session.isIndoor {
                mapButton
            }
            graphButton
        }
        .buttonStyle(GrayButtonStyle())
    }
    
    private static func createStatsContainerViewModel(dataSource: MeasurementsStatisticsDataSource) -> StatisticsContainerViewModel {
        let controller = MeasurementsStatisticsController(dataSource: dataSource,
                                                          calculator: StandardStatisticsCalculator(),
                                                          scheduledTimer: ScheduledTimerSetter(),
                                                          desiredStats: MeasurementStatistics.Statistic.allCases)
        let viewModel = StatisticsContainerViewModel(statsInput: controller)
        controller.output = viewModel
        return viewModel
    }
}

 #if DEBUG
 struct SessionCell_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
        SessionCartView(session: SessionEntity.mock,
                                sessionCartViewModel: SessionCartViewModel(followingSetter: MockSessionFollowingSettable()),
                                thresholds: [.mock, .mock], sessionStoppableFactory: SessionStoppableFactoryDummy(), locationTracker: DummyLocationTrakcer())
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
 }
 #endif
