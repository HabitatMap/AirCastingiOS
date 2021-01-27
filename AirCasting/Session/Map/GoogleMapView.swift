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
    
    let pathPoints: [PathPoint]
    
    func makeUIView(context: Context) -> GMSMapView {
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        GMSPlacesClient.provideAPIKey(GOOGLE_MAP_KEY)
        let camera = GMSCameraPosition.camera(withLatitude: 40.73, longitude: -73.93, zoom: 10.0)
        let frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        let mapView = GMSMapView.map(withFrame: frame, camera: camera)
        
        let path = GMSMutablePath()
        for point in pathPoints {
            let coordinate = point.location
            path.add(coordinate)
        }
        let polyline = GMSPolyline(path: path)
        polyline.map = mapView
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        
    }
    
    typealias UIViewType = GMSMapView
}

struct GoogleMapView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleMapView(pathPoints: [PathPoint(location: CLLocationCoordinate2D(latitude: 40.73,
                                                                              longitude: -73.93),
                                             measurement: 30),
                                   PathPoint(location: CLLocationCoordinate2D(latitude: 40.83,
                                                                              longitude: -73.93),
                                             measurement: 30),
                                   PathPoint(location: CLLocationCoordinate2D(latitude: 40.93,
                                                                              longitude: -73.83),
                                             measurement: 30)])
            .padding()
    }
}

