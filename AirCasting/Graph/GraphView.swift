//
//  GraphView.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct GraphView: View {
    
    let session: SessionEntity
    let thresholds: [SensorThreshold]
    @Binding var selectedStream: MeasurementStreamEntity?
    let sessionStoppableFactory: SessionStoppableFactory
    
    var body: some View {
        VStack(alignment: .trailing) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false, isCollapsed: Binding.constant(false),
                              session: session,
                              sessionStopperFactory: sessionStoppableFactory).padding()
            StreamsView(selectedStream: $selectedStream,
                        isCollapsed: Binding.constant(true),
                        session: session,
                        thresholds: thresholds,
                        measurementPresentationStyle: .showValues).padding(.horizontal)
            if let threshold = thresholds.threshold(for: selectedStream) {
                ZStack(alignment: .topLeading) {
                    if let selectedStream = selectedStream {
                        Graph(stream: selectedStream,
                              thresholds: threshold,
                              isAutozoomEnabled: session.type == .mobile)
                    }
                    StatisticsContainerView()
                }
                NavigationLink(destination: HeatmapSettingsView(changedThresholdValues: threshold.rawThresholdsBinding)) {
                    EditButtonView()
                }
                .padding(.horizontal)
                .padding(.top)
                
                ThresholdsSliderView(threshold: threshold)
                    .padding()
                    // Fixes labels covered by tabbar
                    .padding(.bottom)
            }
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        //Change selected stream
        GraphView(session: .mock, thresholds: [.mock], selectedStream: .constant(nil), sessionStoppableFactory: SessionStoppableFactoryDummy())
    }
}
#endif
