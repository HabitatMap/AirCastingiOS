//
//  Map.swift
//  AirCasting
//
//  Created by Lunar on 25/01/2021.
//

import SwiftUI
import CoreLocation
import Foundation

struct MapView: View {
    
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
    
//    private var coordinates: Coordinates
//    var locationCoordinate: CLLocationCoordinate2D {
//        CLLocationCoordinate2D(
//            latitude: coordinates.latitude,
//            longitude: coordinates.longitude)
//    }
}

//struct Coordinates: Hashable, Codable {
//      var latitude: Double
//      var longitude: Double
//  }

struct Map_Previews: PreviewProvider {
    static var previews: some View {
        MapView(values: .constant([0,1,2,3,10]))
    }
}
