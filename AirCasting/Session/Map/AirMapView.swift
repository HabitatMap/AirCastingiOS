//
//  Map.swift
//  AirCasting
//
//  Created by Lunar on 25/01/2021.
//

import SwiftUI
import CoreLocation
import Foundation

struct AirMapView: View {
    
    @Binding var values: [Float]
    
    var body: some View {
        VStack {
            SessionHeader(action: {}, isExpandButtonNeeded: false)
            ZStack {
                StatisticsContainer()
            }
            MultiSlider(values: $values)
        }
    }
}

struct Map_Previews: PreviewProvider {
    static var previews: some View {
        AirMapView(values: .constant([0,1,2,3,10]))
    }
}
