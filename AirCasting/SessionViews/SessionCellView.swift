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

struct SessionCellView: View {
    
    @State private var isCollapsed = true
    @EnvironmentObject var persistenceController: PersistenceController
    
    let session: SessionEntity
    let thresholds: [SensorThreshold]

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            SessionHeaderView(action:  {
                withAnimation {
                    isCollapsed = !isCollapsed
                }
            }, isExpandButtonNeeded: true,
            session: session,
            thresholds: Array(thresholds))
            if !isCollapsed {
                VStack(alignment: .trailing, spacing: 40) {
                    #warning("The stream should be chosen based on users selection")
                    if let streams = session.measurementStreams {
                        pollutionChart(stream: streams[0] as! MeasurementStreamEntity)
                    }
                    buttons
                }
            }
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

private extension SessionCellView {
    var graphButton: some View {
        NavigationLink(destination: graph) {
            Text("graph")
        }
    }
    
    var mapButton: some View {
        NavigationLink(destination: map) {
            Text("map")
        }
    }
    
    func pollutionChart(stream: MeasurementStreamEntity) -> some View {
        ChartView(stream: stream, thresholds: thresholds[0])
            .frame(height: 200)
    }
    
    var buttons: some View {
        HStack(spacing: 20){
            mapButton
            graphButton
        }
        .buttonStyle(GrayButtonStyle())
    }
    
    var map: AirMapView {
        let dataSource = MapStatsDataSource(stream: session.dbStream!)
        let viewModel = createStatsContainerViewModel(dataSource: dataSource)
        let map = AirMapView(thresholds: thresholds, statsContainerViewModel: viewModel, mapStatsDataSource: dataSource, session: session)
        return map
    }
    
    var graph: GraphView {
        let dataSource = GraphStatsDataSource(stream: session.dbStream!)
        let viewModel = createStatsContainerViewModel(dataSource: dataSource)
        let graph = GraphView(measurementStream: session.dbStream!, thresholds: thresholds, statsContainerViewModel: viewModel, graphStatsDataSource: dataSource)
        return graph
    }
    
    private func createStatsContainerViewModel(dataSource: MeasurementsStatisticsDataSource) -> StatisticsContainerViewModel {
        let output = SwapableMeasurementsStatsOutput()
        let controller = MeasurementsStatisticsController(output: output,
                                                          dataSource: dataSource,
                                                          calculator: StandardStatisticsCalculator(),
                                                          desiredStats: MeasurementStatistics.Statistic.allCases)
        #warning("Change dbStream to selected stream")
        let viewModel = StatisticsContainerViewModel(statsInput: controller, unit: session.dbStream!.measurementShortType ?? "N/A")
        output.output = viewModel
        return viewModel
    }
}

#if DEBUG
struct SessionCell_Previews: PreviewProvider {
    static var previews: some View {
        SessionCellView(session: SessionEntity.mock, thresholds: [.mock, .mock])
            .padding()
            .previewLayout(.sizeThatFits)
            .environmentObject(MicrophoneManager(measurementStreamStorage: PreviewMeasurementStreamStorage()))
            .environmentObject(PersistenceController())
    }
}
#endif
