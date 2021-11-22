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
    @Binding var placePickerDismissed: Bool
    @Binding var isUserInteracting: Bool
    var liveModeOn: Bool
    typealias UIViewType = GMSMapView
    let pathPoints: [PathPoint]
    private(set) var threshold: SensorThreshold?
    var isMyLocationEnabled: Bool = false
    private var onPositionChange: (([PathPoint]) -> ())? = nil
    var heatmap: Heatmap? = nil
    var isSessionFixed: Bool
    
    init(pathPoints: [PathPoint], threshold: SensorThreshold? = nil, isMyLocationEnabled: Bool = false, placePickerDismissed: Binding<Bool>, isUserInteracting: Binding<Bool>, isSessionActive: Bool = false, isSessionFixed: Bool = false) {
        self.pathPoints = pathPoints
        self.threshold = threshold
        self.isMyLocationEnabled = isMyLocationEnabled
        self._placePickerDismissed = placePickerDismissed
        self._isUserInteracting = isUserInteracting
        self.liveModeOn = isSessionActive
        self.isSessionFixed = isSessionFixed
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        GMSPlacesClient.provideAPIKey(GOOGLE_PLACES_KEY)
        
        let startingPoint = setStartingPoint(points: pathPoints)
        
        let mapView = GMSMapView.map(withFrame: .zero,
                                     camera: startingPoint)
        mapView.settings.myLocationButton = liveModeOn
        mapView.delegate = context.coordinator
        mapView.isMyLocationEnabled = isMyLocationEnabled
        polylineDrawing(mapView, context: context)
        context.coordinator.currentlyDisplayedPathPoints = pathPoints
        context.coordinator.currentThreshold = ThresholdWitness(sensorThreshold: threshold)
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
        guard isUserInteracting else { return }
        let thresholdWitness = ThresholdWitness(sensorThreshold: self.threshold)
        if pathPoints != context.coordinator.currentlyDisplayedPathPoints ||
            thresholdWitness != context.coordinator.currentThreshold {
            polylineDrawing(uiView, context: context)
            context.coordinator.currentlyDisplayedPathPoints = pathPoints
            context.coordinator.currentThreshold = ThresholdWitness(sensorThreshold: threshold)
        }
        placePickerDismissed ? uiView.moveCamera(cameraUpdate) : nil
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
        guard liveModeOn else {
            let pathPointsBoundingBox = pathPoints.reduce(initialBounds) { bounds, point in
                bounds.includingCoordinate(point.location)
            }
            return GMSCameraUpdate.fit(pathPointsBoundingBox, withPadding: 1.0)
        }
        let pathPointsBoundingBox = initialBounds.includingCoordinate(pathPoints.last!.location)
        return GMSCameraUpdate.fit(pathPointsBoundingBox, withPadding: 1.0)
    }
    
    func setStartingPoint(points: [PathPoint]) -> GMSCameraPosition {
        if let lastPoint = points.last {
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
        
        return GoogleMapView.color(value: measurement, threshold: thresholds)
    }
    
    static func color(value: Int32, threshold: SensorThreshold?) -> UIColor {
        guard let threshold = threshold else { return .white }
        
        let veryLow = threshold.thresholdVeryLow
        let low = threshold.thresholdLow
        let medium = threshold.thresholdMedium
        let high = threshold.thresholdHigh
        let veryHigh = threshold.thresholdVeryHigh
        
        switch value {
        case veryLow ..< low:
            return UIColor.aircastingGreen
        case low ..< medium:
            return UIColor.aircastingYellow
        case medium ..< high:
            return UIColor.aircastingOrange
        case high ... veryHigh:
            return UIColor.aircastingRed
        default:
            return UIColor.aircastingGray
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
        
        if let last = pathPoints.last {
            let mainPoint = UIImage.imageWithColor(color: color(point: last), size: CGSize(width: Constants.Map.dotWidth, height: Constants.Map.dotHeight))
            dot.icon = mainPoint
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
    
    mutating func drawHeatmap(_ uiView: GMSMapView) {
        if isSessionFixed { return }
        
        let mapWidth = uiView.frame.width
        let mapHeight = uiView.frame.height
        
        if heatmap != nil {
            heatmap?.remove()
            heatmap = nil
        }
        if let threshold = threshold {
            heatmap = Heatmap(uiView, sensorThreshold: threshold, mapWidth: Int(mapWidth), mapHeight: Int(mapHeight))
            heatmap?.drawHeatMap(pathPoints: pathPoints)
        }
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, GMSMapViewDelegate {
        
        var parent: GoogleMapView!
        let polyline = GMSPolyline()
        let dot = GMSMarker()
        var currentlyDisplayedPathPoints = [PathPoint]()
        var currentThreshold: ThresholdWitness?
        
        init(_ parent: GoogleMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            let lat = mapView.projection.coordinate(for: mapView.center).latitude
            let len = mapView.projection.coordinate(for: mapView.center).longitude
            parent.tracker.googleLocation = [PathPoint(location: CLLocationCoordinate2D(latitude: lat, longitude: len), measurementTime: Date().currentUTCTimeZoneDate, measurement: 20.0)]
            #warning("Do something with hard coded measurement")
            positionChanged(for: mapView)
            
            shouldAutoTrack = false
        }
        
        func mapView(_ mapView: GMSMapView, idleAt cameraPosition: GMSCameraPosition) {
            parent.drawHeatmap(mapView)
        }
        
        func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
            centerMap(for: mapView)
            return true
        }
        
        func centerMap(for mapView: GMSMapView) {
            let camera = GMSCameraPosition.camera(withLatitude: parent.tracker.locationManager.location!.coordinate.latitude,
                                                  longitude: parent.tracker.locationManager.location!.coordinate.longitude,
                                                  zoom: 16)
            mapView.animate(to: camera)
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
                      threshold: .mock,
                      placePickerDismissed: .constant(false),
                      isUserInteracting: .constant(true))
            .padding()
    }
}
#endif
