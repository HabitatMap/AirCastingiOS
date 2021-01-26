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
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        GMSPlacesClient.provideAPIKey(GOOGLE_MAP_KEY)
        let camera = GMSCameraPosition.camera(withLatitude: 40.73, longitude: -73.93, zoom: 10.0)
        let frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        let mapView = GMSMapView.map(withFrame: frame, camera: camera)
        
        let marker = GMSMarker()
              marker.position = CLLocationCoordinate2D(latitude: 40.73, longitude: -73.93)
              marker.title = "New York"
              marker.snippet = "NY"
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

