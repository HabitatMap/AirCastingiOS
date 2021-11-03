// Created by Lunar on 03/11/2021.
//

import AirCastingStyling
import Charts
import SwiftUI

struct DormantSessionCardView: View {
    @State private var isCollapsed = true
    @State private var selectedStream: MeasurementStreamEntity?
    @State private var isMapButtonActive = false
    @State private var isGraphButtonActive = false
    @State private var showLoadingIndicator = false
    var session: SessionEntity
    @EnvironmentObject var selectedSection: SelectSection
    let sessionCartViewModel: SessionCartViewModel
    let thresholds: [SensorThreshold]
    let sessionStoppableFactory: SessionStoppableFactory
    let measurementStreamStorage: MeasurementStreamStorage

    init(session: SessionEntity,
         sessionCartViewModel: SessionCartViewModel,
         thresholds: [SensorThreshold],
         sessionStoppableFactory: SessionStoppableFactory,
         measurementStreamStorage: MeasurementStreamStorage) {
        self.session = session
        self.sessionCartViewModel = sessionCartViewModel
        self.thresholds = thresholds
        self.measurementStreamStorage = measurementStreamStorage
    }
    
    var shouldShowValues: MeasurementPresentationStyle {
        return isCollapsed ? .hideValues : .showValues
    }
    
    var hasStreams: Bool {
        session.allStreams != nil || session.allStreams != []
    }
    
    var body: some View {
        if #available(iOS 15, *) {
            let _ = print(Self._printChanges())
        }
        sessionCard
    }
    
    var sessionCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            if hasStreams {
                measurements
                VStack(alignment: .trailing, spacing: 10) {
                    if !isCollapsed {
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
    
    private func selectDefaultStreamIfNeeded(streams: [MeasurementStreamEntity]) {
        if selectedStream == nil {
            selectedStream = streams.first
        }
    }
}

private extension DormantSessionCardView {
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
    
    func descriptionText(stream: MeasurementStreamEntity) -> some View {
        return Text("\(Strings.SessionCartView.avgSessionMin) \(stream.unitSymbol ?? "")")
    }
    
    func displayButtons(thresholds: [SensorThreshold]) -> some View {
        HStack(spacing: 20) {
            Spacer()
            !session.isIndoor ? mapButton : nil
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
        SessionCartView(session: SessionEntity.mock,
                                sessionCartViewModel: SessionCartViewModel(followingSetter: MockSessionFollowingSettable()),
                        thresholds: [.mock, .mock], sessionStoppableFactory: SessionStoppableFactoryDummy(), measurementStreamStorage: PreviewMeasurementStreamStorage())
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
 }
 #endif

