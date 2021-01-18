//
//  GraphView.swift
//  AirCasting
//
//  Created by Lunar on 13/01/2021.
//

import SwiftUI

struct GraphView: View {
    @State private var values: [Float] = [30, 56, 74]
    var body: some View {
        VStack{
            SessionHeader(action: {}, isExpandButtonNeeded: false)
            Spacer()
            PollutionGraph(values: values)
            MultiSlider(values: $values)
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        GraphView()
    }
}
