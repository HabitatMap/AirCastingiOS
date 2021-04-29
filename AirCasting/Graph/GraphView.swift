//
//  GraphView.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct GraphView: View {
    
    var thresholds: [SensorThreshold]
    
    var body: some View {
        VStack(alignment: .trailing) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false,
                              // TODO: replace mocked session
                              session: SessionEntity.mock,
                              thresholds: [.mock]).padding()
            
            ZStack(alignment: .topLeading) {
                Graph(thresholds: thresholds[0])
                StatisticsContainerView()
            }
            
            NavigationLink(destination: HeatmapSettingsView(changedThresholdValues: thresholds[0].rawThresholdsBinding)) {
                EditButtonView()
            }
            .padding()
            
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
        GraphView(thresholds: [.mock])
    }
}
#endif
