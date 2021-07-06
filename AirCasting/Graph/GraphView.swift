//
//  GraphView.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct GraphView: View {
    let measurementStream: MeasurementStreamEntity
    let thresholds: [SensorThreshold]
    let statsContainerViewModel: StatisticsContainerViewModel
    let graphStatsDataSource: GraphStatsDataSource
    
    private var session: SessionEntity { measurementStream.session }
    
    var body: some View {
        VStack(alignment: .trailing) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false,
                              session: session,
                              thresholds: thresholds).padding()
            
            ZStack(alignment: .topLeading) {
                #warning("Replace dbStream with currently selected")
                Graph(stream: session.dbStream!,
                      thresholds: thresholds[0],
                      isAutozoomEnabled: session.type == .mobile).onDateRangeChange { startDate, endDate in
                        graphStatsDataSource.dateRange = startDate...endDate
                        statsContainerViewModel.adjustForNewData()
                      }
                StatisticsContainerView(statsContainerViewModel: statsContainerViewModel)
            }
            
            NavigationLink(destination: HeatmapSettingsView(changedThresholdValues: thresholds[0].rawThresholdsBinding)) {
                EditButtonView()
            }
            .padding(.horizontal)
            .padding(.top)
            
            ThresholdsSliderView(threshold: thresholds[0])
                .padding()
                // Fixes labels covered by tabbar
                .padding(.bottom)
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        GraphView(measurementStream: .mock,
                  thresholds: [.mock],
                  statsContainerViewModel: StatisticsContainerViewModel(statsInput: MeasurementsStatisticsInputMock(), unit: "dB"),
                  graphStatsDataSource: GraphStatsDataSource(stream: .mock))
    }
}
#endif
