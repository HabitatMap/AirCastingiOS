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
        
        let startingPoint = setStartingPoint(points: pathPoints,
                                             zoom: 15)
        
        let frame = CGRect(x: 0, y: 0,
                           width: 300,
                           height: 300)
        let mapView = GMSMapView.map(withFrame: frame,
                                     camera: startingPoint)
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
        
        // Update starting point
        if !context.coordinator.didSetInitLocation && !pathPoints.isEmpty {
            let updatedCameraPosition = setStartingPoint(points: pathPoints,
                                                         zoom: 15)
            DispatchQueue.main.async {
                uiView.camera = updatedCameraPosition
            }
            context.coordinator.didSetInitLocation = true
        }
        polyline.spans = spans
        polyline.strokeWidth = 6
        polyline.map = uiView
    }
    
    func setStartingPoint(points: [PathPoint], zoom: Float) -> GMSCameraPosition {
        if let lastPoint = points.last {
            let long = lastPoint.location.longitude
            let lat = lastPoint.location.latitude
            let newCameraPosition =  GMSCameraPosition.camera(withLatitude: lat,
                                                              longitude: long,
                                                              zoom: zoom)
            return newCameraPosition
        } else {
            let appleParkPostion = GMSCameraPosition.camera(withLatitude: 37.35,
                                                            longitude: -122.05,
                                                            zoom: zoom)
            return appleParkPostion
        }
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
    
    
    class Coordinator {
        var didSetInitLocation: Bool = false
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
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

