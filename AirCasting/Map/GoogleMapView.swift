//
//  GoogleMapView.swift
//  AirCasting
//
//  Created by Lunar on 26/01/2021.
//

import UIKit
import SwiftUI
import GoogleMaps
import GooglePlaces

struct GoogleMapView: UIViewRepresentable {
    @EnvironmentObject var tracker: LocationTracker
    typealias UIViewType = GMSMapView
    let pathPoints: [PathPoint]
    private(set) var threshold: SensorThreshold?
    var isMyLocationEnabled: Bool = false
    private var onPositionChange: (([PathPoint]) -> ())? = nil
    
    init(pathPoints: [PathPoint], threshold: SensorThreshold? = nil, isMyLocationEnabled: Bool = false) {
        self.pathPoints = pathPoints
        self.threshold = threshold
        self.isMyLocationEnabled = isMyLocationEnabled
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        GMSPlacesClient.provideAPIKey(GOOGLE_PLACES_KEY)
        
        let startingPoint = setStartingPoint(points: pathPoints)
        
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
    
    /// Adds an action for when the map viewport is changed.
    /// - Parameter action: an action block that takes an array of currently visible `PathPoint`s.
    func onPositionChange(action: @escaping (_ visiblePoints: [PathPoint]) -> ()) -> Self {
        var newSelf = self
        newSelf.onPositionChange = action
        return newSelf
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // Drawing the path
        let path = GMSMutablePath()
        for point in pathPoints {
            let coordinate = point.location
            path.add(coordinate)
        }
        let polyline = context.coordinator.polyline
        let spans = pathPoints.map { point -> GMSStyleSpan in
            let color = colorPolyline(point: point)
            return GMSStyleSpan(style: GMSStrokeStyle.solidColor(color),
                                segments: 1)
        }

        polyline.path = path
        polyline.spans = spans
        polyline.strokeWidth = CGFloat(Constants.Polyline.width)
        polyline.map = uiView
        
        // Update camera's starting point
        if context.coordinator.shouldAutoTrack {
            let updatedCameraPosition = setStartingPoint(points: pathPoints)
            DispatchQueue.main.async {
                uiView.moveCamera(cameraUpdate)
            }
        }
    }
    
    var cameraUpdate: GMSCameraUpdate {
        guard !pathPoints.isEmpty else {
            let location = tracker.googleLocation.last?.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            return GMSCameraUpdate.setTarget(location)
        }
        
        var north = -90.0
        var south = 90.0
        var east = -180.0
        var west = 180.0
        
        pathPoints
            .forEach { point in
                let latitude = point.location.latitude
                let longitude = point.location.longitude
                
                north = max(north, latitude)
                south = min(south, latitude)
                east = max(east, longitude)
                west = min(west, longitude)
            }
        
        let southWest = CLLocationCoordinate2D(latitude: south, longitude: west)
        let northEast = CLLocationCoordinate2D(latitude: north, longitude: east)
        
        let pathPointsBoundingBox = GMSCoordinateBounds(coordinate: southWest, coordinate: northEast)
        return GMSCameraUpdate.fit(pathPointsBoundingBox, withPadding: 1.0)
    }
    
    func setStartingPoint(points: [PathPoint]) -> GMSCameraPosition {
        if let lastPoint = tracker.googleLocation.last {
            let long = lastPoint.location.longitude
            let lat = lastPoint.location.latitude
            
            let newCameraPosition =  GMSCameraPosition.camera(withLatitude: lat,
                                                              longitude: long,
                                                              zoom: 18)
            return newCameraPosition
        } else {
            let appleParkPosition = GMSCameraPosition.camera(withLatitude: 37.35,
                                                            longitude: -122.05,
                                                            zoom: 18)
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
        let polyline = GMSPolyline()
        
        init(_ parent: GoogleMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            let lat = mapView.projection.coordinate(for: mapView.center).latitude
            let len = mapView.projection.coordinate(for: mapView.center).longitude
            parent.tracker.googleLocation = [PathPoint(location: CLLocationCoordinate2D(latitude: lat, longitude: len), measurementTime: Date(), measurement: 20.0)]
            #warning("Do something with hard coded measurement")
            positionChanged(for: mapView)
            
            shouldAutoTrack = false
        }
        
        private func positionChanged(for mapView: GMSMapView) {
            let visibleRegion = mapView.projection.visibleRegion()
            let bounds = GMSCoordinateBounds(region: visibleRegion)
            let visiblePathPoints = parent.pathPoints.filter { bounds.contains($0.location) }
            parent.onPositionChange?(visiblePathPoints)
        }

        var shouldAutoTrack: Bool = true
        var myLocationSink: Any?
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

#if DEBUG
struct GoogleMapView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleMapView(pathPoints: [PathPoint(location: CLLocationCoordinate2D(latitude: 40.73,
                                                                              longitude: -73.93),
                                             measurementTime: .distantPast,
                                             measurement: 30),
                                   PathPoint(location: CLLocationCoordinate2D(latitude: 40.83,
                                                                              longitude: -73.93),
                                             measurementTime: .distantPast,
                                             measurement: 30),
                                   PathPoint(location: CLLocationCoordinate2D(latitude: 40.93,
                                                                              longitude: -73.83),
                                             measurementTime: .distantPast,
                                             measurement: 30)],
                      threshold: .mock)
            .padding()
    }
}
#endif
