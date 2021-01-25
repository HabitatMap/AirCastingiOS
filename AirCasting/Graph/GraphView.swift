//
//  GraphView.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct GraphView: View {
    
    // TO DO: Change key name
    @AppStorage("values") var values: [Float] = [0, 70, 120, 170, 200]
    
    var body: some View {
        VStack(alignment: .trailing) {
            SessionHeader(action: {}, isExpandButtonNeeded: false)
                .padding()
            
            ZStack(alignment: .topLeading) {
                PollutionGraph(values: values)
                StatisticsContainer()
            }
            NavigationLink(destination: HeatmapSettings(changedValues: $values)) {
                EditButton()
            }
            .padding()
            
            MultiSlider(values: $values)
                .padding()
            
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        GraphView()
    }
}
