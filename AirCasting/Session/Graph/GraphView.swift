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
            SessionHeader(action: {}, isExpandButtonNeeded: false)
                .padding()
            
            ZStack(alignment: .topLeading) {
                Graph(values: values)
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
        GraphView(values: .constant([0,1,2,3]))
    }
}
