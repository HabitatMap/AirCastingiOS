//
//  SessionCell.swift
//  AirCasting
//
//  Created by Lunar on 08/01/2021.
//

import AirCastingStyling
import Charts
import SwiftUI

struct SessionCardView: View {
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
    @StateObject private var chartViewModel: ChartViewModel

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
        self._mapStatsViewModel = .init(wrappedValue: SessionCardView.createStatsContainerViewModel(dataSource: mapDataSource, session: session))
        let graphDataSource = GraphStatsDataSource()
        self._graphStatsDataSource = .init(wrappedValue: graphDataSource)
        self._graphStatsViewModel = .init(wrappedValue: SessionCardView.createStatsContainerViewModel(dataSource: graphDataSource, session: session))
        self._chartViewModel = .init(wrappedValue: ChartViewModel(session: session, persistence: PersistenceController.shared))
    }
    
    var shouldShowValues: MeasurementPresentationStyle {
        // We need to specify selectedSection to show values for fixed session only in following tab
        let shouldShow = isCollapsed && ( (session.isFixed && selectedSection.selectedSection == SelectedSection.fixed) || session.isDormant)
        return shouldShow ? .hideValues : .showValues
    }
    
    var showChart: Bool {
        (session.isMobile && session.isActive) || (session.isFixed && selectedSection.selectedSection == SelectedSection.following)
    }
    
    var hasStreams: Bool {
        session.allStreams != nil || session.allStreams != []
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
            if hasStreams {
                measurements
                VStack(alignment: .trailing, spacing: 10) {
                    if !isCollapsed {
                        showChart ? pollutionChart(thresholds: thresholds) : nil
                        displayButtons(thresholds: thresholds)
                    }
                }
            } else {
                SessionLoadingView()
            }
        }
        .onAppear {
            selectDefaultStreamIfNeeded(streams: session.sortedStreams ?? [])
        }
        .onChange(of: session.sortedStreams) { newValue in
            selectDefaultStreamIfNeeded(streams: newValue ?? [])
        }
        .onChange(of: selectedStream, perform: { [weak graphStatsDataSource, weak mapStatsDataSource, weak chartViewModel] newStream in
            graphStatsDataSource?.stream = newStream
            mapStatsDataSource?.stream = newStream
            chartViewModel?.stream = newStream
        })
        .font(Fonts.regularHeading4)
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
    
    var standaloneSessionCard: some View {
        StandaloneSessionCard(session: session, sessionStopperFactory: sessionStoppableFactory)
    }
    
    private func selectDefaultStreamIfNeeded(streams: [MeasurementStreamEntity]) {
        if selectedStream == nil {
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
                }
            },
            isExpandButtonNeeded: true,
            isCollapsed: $isCollapsed,
            session: session,
            sessionStopperFactory: sessionStoppableFactory
        )
    }
    
    private var measurements: some View {
        ABMeasurementsView(viewModelProvider: {
            DefaultSyncingMeasurementsViewModel(measurementStreamStorage: measurementStreamStorage,
                                                sessionDownloader: SessionDownloadService(client: URLSession.shared,
                                                authorization: UserAuthenticationSession(),
                                                responseValidator: DefaultHTTPResponseValidator()),
                                                session: session)
                                                },
                                                session: session,
                                                isCollapsed: $isCollapsed,
                                                selectedStream: $selectedStream,
                                                thresholds: thresholds,
                                                measurementPresentationStyle: shouldShowValues)
    }
    
    private var graphButton: some View {
        Button {
            isGraphButtonActive = true
        } label: {
            Text(Strings.SessionCartView.graph)
                .font(Fonts.semiboldHeading2)
                .padding(.horizontal, 8)
        }
    }
    
    private var mapButton: some View {
        Button {
            isMapButtonActive = true
        } label: {
            Text(Strings.SessionCartView.map)
                .font(Fonts.semiboldHeading2)
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
        return VStack() {
            if let selectedStream = selectedStream {
                Group { 
                    ChartView(thresholds: thresholds,
                              viewModel: chartViewModel)
                        .frame(height: 120)
                        .disabled(true)
                    HStack() {
                            startTime
                            Spacer()
                            descriptionText(stream: selectedStream)
                            Spacer()
                            endTime
                    }.foregroundColor(.aircastingGray)
                        .font(Fonts.semiboldHeading2)
                }
                .onAppear {
                    chartViewModel.refreshChart()
                }
            }
        }
    }
    
    var startTime: some View {
        let formatter = DateFormatters.SessionCartView.pollutionChartDateFormatter
            
        guard let start = chartViewModel.chartStartTime else { return Text("") }
        
        let string = formatter.string(from: start)
        return Text(string)
        }
    
    var endTime: some View {
        let formatter = DateFormatters.SessionCartView.pollutionChartDateFormatter
        
        let end = chartViewModel.chartEndTime ?? Date().currentUTCTimeZoneDate
        
        let string = formatter.string(from: end)
        return Text(string)
        }
    
    func descriptionText(stream: MeasurementStreamEntity) -> some View {
        return Text("\(stream.session.isMobile ? Strings.SessionCartView.avgSessionMin : Strings.SessionCartView.avgSessionH) \(stream.unitSymbol ?? "")")
    }
    
    func displayButtons(thresholds: [SensorThreshold]) -> some View {
        HStack(spacing: 20) {
            if sessionCartViewModel.isFollowing && session.type == .fixed {
                unFollowButton
            } else if session.type == .fixed {
                followButton
            }
            Spacer()
            !session.isIndoor ? mapButton : nil
            graphButton
        }
        .buttonStyle(GrayButtonStyle())
    }
    
    private static func createStatsContainerViewModel(dataSource: MeasurementsStatisticsDataSource, session: SessionEntity) -> StatisticsContainerViewModel {
        var computeStatisticsInterval: Double? = nil
        
        if session.isActive {
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
         let mapView = AirMapView(thresholds: thresholds,
                                  statsContainerViewModel: mapStatsViewModel,
//                                  mapStatsDataSource: mapStatsDataSource,
                                  session: session,
                                  showLoadingIndicator: $showLoadingIndicator,
                                  selectedStream: $selectedStream,
                                  sessionStoppableFactory: sessionStoppableFactory,
                                  measurementStreamStorage: measurementStreamStorage)
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
                                   graphStatsDataSource: graphStatsDataSource,
                                   sessionStoppableFactory: sessionStoppableFactory,
                                   measurementStreamStorage: measurementStreamStorage)
             .foregroundColor(.aircastingDarkGray)
         
         return NavigationLink(destination: graphView,
                               isActive: $isGraphButtonActive,
                               label: {
                                 EmptyView()
                               })
     }
}

 #if DEBUG
 struct SessionCell_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
        SessionCardView(session: SessionEntity.mock,
                                sessionCartViewModel: SessionCartViewModel(followingSetter: MockSessionFollowingSettable()),
                        thresholds: [.mock, .mock], sessionStoppableFactory: SessionStoppableFactoryDummy(), measurementStreamStorage: PreviewMeasurementStreamStorage())
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
 }
 #endif

