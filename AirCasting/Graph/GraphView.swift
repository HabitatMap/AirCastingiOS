//
//  GraphView.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct GraphView: View {
    
    let session: SessionEntity
    let threshold: SensorThreshold
    @Binding var selectedStream: MeasurementStreamEntity?
    
    var body: some View {
        VStack(alignment: .trailing) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false,
                              session: session,
                              threshold: threshold,
                              selectedStream: $selectedStream).padding()
            
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
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        #warning("Change selected stream")
        GraphView(session: .mock, threshold: .mock, selectedStream: .constant(nil))
    }
}
#endif
