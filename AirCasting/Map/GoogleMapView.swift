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
    private(set) var threshold: SensorThreshold?
    var isMyLocationEnabled: Bool = false
    
    func makeUIView(context: Context) -> GMSMapView {
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        GMSPlacesClient.provideAPIKey(GOOGLE_PLACES_KEY)
        
        let startingPoint = setStartingPoint(points: pathPoints)
        
        let frame = CGRect(x: 0, y: 0,
                           width: 300,
                           height: 300)
        let mapView = GMSMapView.map(withFrame: frame,
                                     camera: startingPoint)
        
        print("CENTER MAP: \(mapView.projection.coordinate(for: mapView.center))")
        
        mapView.isMyLocationEnabled = isMyLocationEnabled
        
        context.coordinator.myLocationSink = mapView.publisher(for: \.myLocation)
            .sink { [weak mapView] (location) in
                guard let coordinate = location?.coordinate else { return }
                mapView?.animate(toLocation: coordinate)
            }
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
            let updatedCameraPosition = setStartingPoint(points: pathPoints)
            DispatchQueue.main.async {
                uiView.camera = updatedCameraPosition
            }
            context.coordinator.didSetInitLocation = true
        }
        polyline.spans = spans
        polyline.strokeWidth = 6
        polyline.map = uiView
    }
    
    func setStartingPoint(points: [PathPoint]) -> GMSCameraPosition {
        if let lastPoint = points.last {
            let long = lastPoint.location.longitude
            let lat = lastPoint.location.latitude
            let newCameraPosition =  GMSCameraPosition.camera(withLatitude: lat,
                                                              longitude: long,
                                                              zoom: 17)
            return newCameraPosition
        } else {
            let appleParkPosition = GMSCameraPosition.camera(withLatitude: 37.35,
                                                            longitude: -122.05,
                                                            zoom: 17)
            return appleParkPosition
        }
    }

    func colorPolyline(point: PathPoint) -> UIColor {
        let measurement = Int32(point.measurement)
        guard let thresholds = threshold else { return .white }
        
        let veryLow = thresholds.thresholdVeryLow
        let low = thresholds.thresholdLow
        let medium = thresholds.thresholdMedium
        let high = thresholds.thresholdHigh
        let veryHigh = thresholds.thresholdVeryHigh
        
        switch measurement {
        case veryLow ..< low:
            return UIColor.aircastingGreen
        case low ..< medium:
            return UIColor.aircastingYellow
        case medium ..< high:
            return UIColor.aircastingOrange
        case high ... veryHigh:
            return UIColor.aircastingRed
        default:
            return UIColor.white
        }
    }
    
    class Coordinator {
        var didSetInitLocation: Bool = false   
        var myLocationSink: Any?
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

#if DEBUG
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
                      threshold: .mock)
            .padding()
    }
}
#endif
