//
//  SessionCell.swift
//  AirCasting
//
//  Created by Lunar on 08/01/2021.
//

import SwiftUI
import CoreLocation
import CoreData
import Charts
import AirCastingStyling

struct SessionCartView: View {
    
    @State private var isCollapsed = true
    @State private var selectedStream: MeasurementStreamEntity?
    
    @ObservedObject var session: SessionEntity
    let thresholds: [SensorThreshold]

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
        .onChange(of: session.allStreams) { _ in
            selectedStream = session.allStreams?.first
        }
        .onAppear() {
            selectedStream = session.allStreams?.first
        }
        .font(Font.moderate(size: 13, weight: .regular))
        .foregroundColor(.aircastingGray)
        .padding()
        .background(
            Color.white
                .shadow(color: Color(red: 205/255, green: 209/255, blue: 214/255, opacity: 0.36), radius: 9, x: 0, y: 1)
        )
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
            session: session)
    }
    
    func graphButton(thresholds: [SensorThreshold]) -> some View {
        #warning("Move to dynamic here!")
        let dataSource = GraphStatsDataSource(stream: selectedStream!)
        let viewModel = createStatsContainerViewModel(dataSource: dataSource)
        return NavigationLink(destination: GraphView(session: session,
                                              thresholds: thresholds,
                                              selectedStream: $selectedStream,
                                              statsContainerViewModel: viewModel,
                                              graphStatsDataSource: dataSource)) {
            Text("graph")
        }
    }
    
    func mapButton(thresholds: [SensorThreshold]) -> some View {
        #warning("Move to dynamic here!")
        let dataSource = MapStatsDataSource(stream: selectedStream!)
        let viewModel = createStatsContainerViewModel(dataSource: dataSource)
        return NavigationLink(destination: AirMapView(thresholds: thresholds,
                                                      statsContainerViewModel: viewModel,
                                                      mapStatsDataSource: dataSource,
                                                      session: session,
                                                      selectedStream: $selectedStream)) {
            Text("map")
        }
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
            mapButton(thresholds: thresholds)
            graphButton(thresholds: thresholds)
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
        SessionCartView(session: SessionEntity.mock, thresholds: [.mock, .mock])
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage(), sessionSynchronizer: DummySessionSynchronizer()))
    }
}
#endif
