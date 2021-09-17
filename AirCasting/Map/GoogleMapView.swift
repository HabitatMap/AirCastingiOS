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
       polylineDrawing(uiView, context: context)

        // Update camera's starting point
        guard context.coordinator.shouldAutoTrack else { return }
            DispatchQueue.main.async {
                uiView.moveCamera(cameraUpdate)
                if uiView.camera.zoom > 16 {
                    // The zoom is set automatically somehow which results sometimes in 'too close' map
                    // This helps us to fix it and still manage to fit into the 'bigger picture' if needed because of the long session
                    uiView.animate(toZoom: 16)
                }
            }
        }
    
    var cameraUpdate: GMSCameraUpdate {
        guard !pathPoints.isEmpty else {
            let location = tracker.googleLocation.last?.location ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            return GMSCameraUpdate.setTarget(location)
        }
        let initialBounds = GMSCoordinateBounds()
        let pathPointsBoundingBox = pathPoints.reduce(initialBounds) { bounds, point in
            bounds.includingCoordinate(point.location)
        }
        return GMSCameraUpdate.fit(pathPointsBoundingBox, withPadding: 1.0)
    }
    
    func setStartingPoint(points: [PathPoint]) -> GMSCameraPosition {
        if let lastPoint = tracker.googleLocation.last {
            let long = lastPoint.location.longitude
            let lat = lastPoint.location.latitude
            
            let newCameraPosition =  GMSCameraPosition.camera(withLatitude: lat,
                                                              longitude: long,
                                                              zoom: 16)
            return newCameraPosition
        } else {
            let appleParkPosition = GMSCameraPosition.camera(withLatitude: 37.35,
                                                            longitude: -122.05,
                                                            zoom: 16)
            return appleParkPosition
        }
    }

    func color(point: PathPoint) -> UIColor {
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
    
    func polylineDrawing(_ uiView: GMSMapView, context: Context) {
        // Drawing the path
        let path = GMSMutablePath()
        let dot = context.coordinator.dot
        
        for point in pathPoints {
            let coordinate = point.location
            path.add(coordinate)

            dot.position = coordinate
            dot.map = uiView
        }
        
        if let first = pathPoints.first {
            dot.iconView = UIView()
            dot.iconView?.frame = CGRect(x: 0, y: 0,
                                         width: Constants.Map.dotWidth,
                                         height: Constants.Map.dotHeight)
            dot.iconView?.layer.cornerRadius = CGFloat(Constants.Map.dotRadius)
            dot.iconView?.backgroundColor = color(point: first)
        }
        
        let polyline = context.coordinator.polyline
        let spans = pathPoints.map { point -> GMSStyleSpan in
        let color = color(point: point)
        return GMSStyleSpan(style: GMSStrokeStyle.solidColor(color),
                                segments: 1)
        }

        polyline.path = path
        polyline.spans = spans
        polyline.strokeWidth = CGFloat(Constants.Map.polylineWidth)
        polyline.map = uiView
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, GMSMapViewDelegate {

        var parent: GoogleMapView!
        let polyline = GMSPolyline()
        let dot = GMSMarker()
        
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
