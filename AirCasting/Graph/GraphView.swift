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
                      isAutozoomEnabled: session.type == .mobile)
                StatisticsContainerView()
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
        GraphView(session: .mock, thresholds: [.mock])
    }
}
#endif
