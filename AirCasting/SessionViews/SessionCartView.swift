//
//  SessionCell.swift
//  AirCasting
//
//  Created by Lunar on 08/01/2021.
//

import AirCastingStyling
import Charts
import CoreData
import SwiftUI

struct SessionCartView: View {
    @State private var isCollapsed = true
    @State private var selectedStream: MeasurementStreamEntity?
    @State private var isMapButtonActive = false
    @State private var isGraphButtonActive = false
    @State private var showLoadingIndicator = false
    @ObservedObject var session: SessionEntity
    @EnvironmentObject var selectedSection: SelectSection
    let sessionCartViewModel: SessionCartViewModel
    let thresholds: [SensorThreshold]
    let sessionStoppableFactory: SessionStoppableFactory
    let measurementStreamStorage: MeasurementStreamStorage
    
    @StateObject private var mapStatsDataSource: MapStatsDataSource
    @StateObject private var mapStatsViewModel: StatisticsContainerViewModel
    @StateObject private var graphStatsDataSource: GraphStatsDataSource
    @StateObject private var graphStatsViewModel: StatisticsContainerViewModel
    
    init(session: SessionEntity,
         sessionCartViewModel: SessionCartViewModel,
         thresholds: [SensorThreshold],
         sessionStoppableFactory: SessionStoppableFactory,
         measurementStreamStorage: MeasurementStreamStorage) {
        self.session = session
        self.sessionCartViewModel = sessionCartViewModel
        self.thresholds = thresholds
        self.sessionStoppableFactory = sessionStoppableFactory
        self.measurementStreamStorage = measurementStreamStorage
        let mapDataSource = MapStatsDataSource()
        self._mapStatsDataSource = .init(wrappedValue: mapDataSource)
        self._mapStatsViewModel = .init(wrappedValue: SessionCartView.createStatsContainerViewModel(dataSource: mapDataSource))
        let graphDataSource = GraphStatsDataSource()
        self._graphStatsDataSource = .init(wrappedValue: graphDataSource)
        self._graphStatsViewModel = .init(wrappedValue: SessionCartView.createStatsContainerViewModel(dataSource: graphDataSource))
    }

    var shouldShowValues: MeasurementPresentationStyle {
        // We need to specify selectedSection to show values for fixed session only in following tab
        let shouldShow = isCollapsed && ( (session.isFixed && selectedSection.selectedSection == SelectedSection.fixed) || session.isDormant)
        return shouldShow ? .hideValues : .showValues
    }

    var showChart: Bool {
        (!isCollapsed && session.isMobile && session.isActive) || (!isCollapsed && session.isFixed && selectedSection.selectedSection == SelectedSection.following)
    }
    var hasStreams: Bool {
        session.allStreams != nil || session.allStreams != []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            header
            if hasStreams {
                Measurements
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
        .onChange(of: selectedStream, perform: { [weak graphStatsDataSource, weak mapStatsDataSource] newStream in
            graphStatsDataSource?.stream = newStream
            mapStatsDataSource?.stream = newStream
        })
        .onAppear {
            selectDefaultStreamIfNeeded(streams: session.sortedStreams ?? [])
        }
        .onChange(of: session.sortedStreams) { newValue in
            selectDefaultStreamIfNeeded(streams: newValue ?? [])
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
    
    var Measurements: some View {
        ABMeasurementsView(session: session,
                           isCollapsed: $isCollapsed,
                           selectedStream: $selectedStream,
                           showLoadingIndicator: $showLoadingIndicator,
                           thresholds: thresholds,
                           measurementPresentationStyle: shouldShowValues,
                           measurementStreamStorage: measurementStreamStorage)
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
                                 showLoadingIndicator: $showLoadingIndicator,
                                 selectedStream: $selectedStream,
                                 sessionStoppableFactory: sessionStoppableFactory,
                                 measurementStreamStorage: measurementStreamStorage)
        
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
                                  sessionStoppableFactory: sessionStoppableFactory,
                                  measurementStreamStorage: measurementStreamStorage)
        return NavigationLink(destination: graphView,
                              isActive: $isGraphButtonActive,
                              label: {
                                EmptyView()
                              })
    }
    
    func pollutionChart(thresholds: [SensorThreshold]) -> some View {
        
        let start = session.startTime ?? Date()
        let end = session.endTime ?? Date()
        
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let startTime = dateFormatter.string(from: start)
        let endTime = dateFormatter.string(from: end)
        
        return VStack() {
            Group {
                if let selectedStream = selectedStream {
                    ChartView(stream: selectedStream,
                              thresholds: thresholds)
                        .frame(height: 120)
                        .disabled(true)
                    HStack() {
                            Text(startTime)
                            Spacer()
                        Text("\(Strings.SessionCartView.avgSession) \(selectedStream.measurementShortType ?? "")")
                            Spacer()
                            Text(endTime)
                    }.foregroundColor(.aircastingGray)
                    .font(Font.muli(size: 13, weight: .semibold))
                }
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
                                thresholds: [.mock, .mock], sessionStoppableFactory: SessionStoppableFactoryDummy(), measurementStreamStorage: MeasurementStreamStorage.self as! MeasurementStreamStorage)
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
 }
 #endif
