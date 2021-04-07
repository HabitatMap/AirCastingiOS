//
//  GraphView.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct GraphView: View {
    
    @Binding var values: [Float]

    var body: some View {
        VStack(alignment: .trailing) {
            SessionHeaderView(action: {},
                              isExpandButtonNeeded: false,
                              // TODO: replace mocked session
                              session: Session.mock)
                .padding()
            
            ZStack(alignment: .topLeading) {
                Graph(values: values)
                StatisticsContainerView()
            }
            NavigationLink(destination: HeatmapSettingsView(changedValues: $values)) {
                EditButton()
            }
            .padding()
            
            MultiSliderView(values: $values)
                .padding()
                // Fixes labels covered by tabbar
                .padding(.bottom)
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        GraphView(values: .constant([0,1,2,3]))
    }
}
