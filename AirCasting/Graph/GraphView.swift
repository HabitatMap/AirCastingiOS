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
    @Binding var selectedStream: String
    
    var body: some View {
        VStack(alignment: .trailing) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false,
                              session: session,
                              thresholds: thresholds,
                              selectedStream: $selectedStream).padding()
            
            ZStack(alignment: .topLeading) {
                if let selectedStream = session.streamWith(sensorName: selectedStream) {
                    Graph(stream: selectedStream,
                          thresholds: thresholds[0],
                          isAutozoomEnabled: session.type == .mobile)
                }
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
        #warning("Change selected stream")
        GraphView(session: .mock, thresholds: [.mock], selectedStream: .constant("db"))
    }
}
#endif
