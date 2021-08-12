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
    @EnvironmentObject var tracker: LocationTracker
    typealias UIViewType = GMSMapView
    private(set) var threshold: SensorThreshold?
    var isMyLocationEnabled: Bool = false
    
    func makeUIView(context: Context) -> GMSMapView {
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        GMSPlacesClient.provideAPIKey(GOOGLE_PLACES_KEY)
        
        let startingPoint = setStartingPoint(points: tracker.googleLocation)
        
        let mapView = GMSMapView.map(withFrame: .zero,
                                     camera: startingPoint)

        mapView.delegate = context.coordinator

        mapView.isMyLocationEnabled = isMyLocationEnabled
        
        context.coordinator.myLocationSink = mapView.publisher(for: \.myLocation)
            .sink { [weak mapView] (location) in
                guard let coordinate = location?.coordinate else { return }
                mapView?.animate(toLocation: coordinate)
            }
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Self.Context) {
        // Drawing the path
        let path = GMSMutablePath()
        for point in tracker.googleLocation {
            let coordinate = point.location
            path.add(coordinate)
        }
        let polyline = GMSPolyline(path: path)
        
        let spans = tracker.googleLocation.map { point -> GMSStyleSpan in
            let color = colorPolyline(point: point)
            return GMSStyleSpan(style: GMSStrokeStyle.solidColor(color),
                                segments: 1)
        }
        
        
        let updatedCameraPosition = setStartingPoint(points: tracker.googleLocation)
        DispatchQueue.main.async {
            uiView.camera = updatedCameraPosition
        }
        // Update starting point
        if !context.coordinator.didSetInitLocation && !tracker.googleLocation.isEmpty {
            let updatedCameraPosition = setStartingPoint(points: tracker.googleLocation)
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
    
    class Coordinator: NSObject, UINavigationControllerDelegate, GMSMapViewDelegate {

        var parent: GoogleMapView!
        
        init(_ parent: GoogleMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            print("Changing Coordinates to: \(mapView.projection.coordinate(for: mapView.center))")
            let lat = mapView.projection.coordinate(for: mapView.center).latitude
            let len = mapView.projection.coordinate(for: mapView.center).longitude
            parent.tracker.googleLocation = [PathPoint(location: CLLocationCoordinate2D(latitude: lat, longitude: len), measurement: 20.0)]
        }

        var didSetInitLocation: Bool = false   
        var myLocationSink: Any?
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

#if DEBUG
struct GoogleMapView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleMapView()
            .padding()
    }
}
#endif
