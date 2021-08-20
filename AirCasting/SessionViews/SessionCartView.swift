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
        #warning("Move to dynamic here!")
        let dataSource = MapStatsDataSource(stream: selectedStream)
        let viewModel = createStatsContainerViewModel(dataSource: dataSource)
        let mapView = AirMapView(thresholds: thresholds,
                                 statsContainerViewModel: viewModel,
                                 mapStatsDataSource: dataSource,
                                 session: session,
                                 selectedStream: $selectedStream,
                                 sessionStoppableFactory: sessionStoppableFactory)
        
        return NavigationLink(destination: mapView,
                              isActive: $isMapButtonActive,
                              label: {
                                EmptyView()
                              }).onChange(of: selectedStream, perform: { [weak dataSource] newStream in
                                dataSource?.stream = newStream
                              })
    }
    
    var graphNavigationLink: some View {
        #warning("Move to dynamic here!")
        let dataSource = GraphStatsDataSource(stream: selectedStream)
        let viewModel = createStatsContainerViewModel(dataSource: dataSource)
        let graphView = GraphView(session: session,
                                  thresholds: thresholds,
                                  selectedStream: $selectedStream,
                                  statsContainerViewModel: viewModel,
                                  graphStatsDataSource: dataSource,
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
    
    private func createStatsContainerViewModel(dataSource: MeasurementsStatisticsDataSource) -> StatisticsContainerViewModel {
        let output = SwapableMeasurementsStatsOutput()
        let controller = MeasurementsStatisticsController(output: output,
                                                          dataSource: dataSource,
                                                          calculator: StandardStatisticsCalculator(),
                                                          scheduledTimer: ScheduledTimerSetter(),
                                                          desiredStats: MeasurementStatistics.Statistic.allCases)
        #warning("Move to dynamic here")
        let viewModel = StatisticsContainerViewModel(statsInput: controller, unit: selectedStream?.measurementShortType ?? "N/A")
        output.output = viewModel
        return viewModel
    }
}

 #if DEBUG
 struct SessionCell_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
        SessionCartView(session: SessionEntity.mock,
                                sessionCartViewModel: SessionCartViewModel(followingSetter: MockSessionFollowingSettable()),
                                thresholds: [.mock, .mock], sessionStoppableFactory: SessionStoppableFactoryDummy())
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
    }
 }
 #endif
