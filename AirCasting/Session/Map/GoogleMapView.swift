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
    typealias UIViewType = GMSMapView

    let pathPoints: [PathPoint]
    let values: [Float]
    
    func makeUIView(context: Context) -> GMSMapView {
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        GMSPlacesClient.provideAPIKey(GOOGLE_MAP_KEY)
        
        let camera = GMSCameraPosition.camera(withLatitude: 37.33, longitude: -122.03, zoom: 10)
        let frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        let mapView = GMSMapView.map(withFrame: frame, camera: camera)
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // Drawing the path
        let path = GMSMutablePath()
        for point in pathPoints {
            let coordinate = point.location
            path.add(coordinate)
        }
        let polyline = GMSPolyline(path: path)
        
        let spans = pathPoints.map { point -> GMSStyleSpan in
            let color = colorPolyline(point: point)
            return GMSStyleSpan(style: GMSStrokeStyle.solidColor(color),
                                segments: 1)
        }
        polyline.spans = spans
        polyline.strokeWidth = 6
        polyline.map = uiView
    }

    func colorPolyline(point: PathPoint) -> UIColor {
        let measurement = point.measurement
        
        switch measurement {
        case values[0]..<values[1]:
            return UIColor.aircastingGreen
        case values[1]..<values[2]:
            return UIColor.aircastingYellow
        case values[2]..<values[3]:
            return UIColor.aircastingOrange
        case values[3]...values[4]:
            return UIColor.aircastingRed
        default:
            return UIColor.white
        }
    }
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
                                             measurement: 30)],
                      values: [0, 25, 50, 75, 100])
            .padding()
    }
}

