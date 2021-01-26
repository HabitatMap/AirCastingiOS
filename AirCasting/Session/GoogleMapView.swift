//
//  GoogleMapView.swift
//  AirCasting
//
//  Created by Lunar on 26/01/2021.
//

import Foundation
import UIKit
import SwiftUI
import GoogleMaps
import GooglePlaces

struct GoogleMapView: UIViewRepresentable {
    
    
    
    
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        let frame = CGRect(x: 0, y: 0, width: 300, height: 300)
//        let mapView = GMSMapView(frame: frame, camera: camera)
        let mapView = GMSMapView.map(withFrame: frame, camera: camera)
        
        let marker = GMSMarker()
              marker.position = CLLocationCoordinate2D(latitude: -33.86, longitude: 151.20)
              marker.title = "Sydney"
              marker.snippet = "Australia"
              marker.map = mapView
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        
    }
    
    typealias UIViewType = GMSMapView
}

struct GoogleMapView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleMapView()
            .padding()
    }
}

