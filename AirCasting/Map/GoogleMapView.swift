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
import Resolver

struct GoogleMapView: UIViewRepresentable {
    @InjectedObject private var tracker: LocationTracker
    
    @Binding var isUserInteracting: Bool
    @Binding var noteMarketTapped: Bool
    @Binding var noteNumber: Int
    var liveModeOn: Bool
    typealias UIViewType = GMSMapView
    let pathPoints: [PathPoint]
    private(set) var threshold: SensorThreshold?
    var isMyLocationEnabled: Bool = false
    private var onPositionChange: (([PathPoint]) -> ())? = nil
    var isSessionFixed: Bool
    let isMapOnPickerScreen: Bool
    @Binding var mapNotes: [MapNote]
    let showMyLocationButton: Bool
    
    //MARK: - Place picker variables
    @Binding var placePickerIsUpdating: Bool
    @Binding var placePickerLocation: CLLocationCoordinate2D?
    
    init(pathPoints: [PathPoint], threshold: SensorThreshold? = nil, isMyLocationEnabled: Bool = false, placePickerIsUpdating: Binding<Bool>, isUserInteracting: Binding<Bool>, isSessionActive: Bool = false, isSessionFixed: Bool = false, noteMarketTapped: Binding<Bool> = .constant(false), noteNumber: Binding<Int> = .constant(0), mapNotes: Binding<[MapNote]>, showMyLocationButton: Bool = true, isMapOnPickerScreen: Bool = false, placePickerLocation: Binding<CLLocationCoordinate2D?> = .constant(nil)) {
        self.pathPoints = pathPoints
        self.threshold = threshold
        self.isMyLocationEnabled = isMyLocationEnabled
        self._placePickerIsUpdating = placePickerIsUpdating
        self._isUserInteracting = isUserInteracting
        self.liveModeOn = isSessionActive
        self.isSessionFixed = isSessionFixed
        self._noteMarketTapped = noteMarketTapped
        self._noteNumber = noteNumber
        self._mapNotes = mapNotes
        self.showMyLocationButton = showMyLocationButton
        self.isMapOnPickerScreen = isMapOnPickerScreen
        self._placePickerLocation = placePickerLocation
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        let startingPoint = setStartingPoint(points: pathPoints)
        
        let mapView = GMSMapView.map(withFrame: .zero,
                                     camera: startingPoint)
        mapView.settings.myLocationButton = showMyLocationButton
        placeNotes(mapView, notes: mapNotes, context: context)
        do {
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                Log.error("Unable to find style.json")
            }
        } catch {
            Log.error("One or more of the map styles failed to load. \(error)")
        }
        mapView.delegate = context.coordinator
        mapView.isMyLocationEnabled = isMyLocationEnabled
        drawPolyline(mapView, context: context)
        context.coordinator.mapNotesCounter = mapNotes.count
        context.coordinator.currentlyDisplayedPathPoints = pathPoints
        context.coordinator.currentThresholdWitness = ThresholdWitness(sensorThreshold: threshold)
        context.coordinator.currentThreshold = threshold
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
        if mapNotes.count != context.coordinator.mapNotesCounter {
            placeNotes(uiView, notes: mapNotes, context: context)
            drawPolyline(uiView, context: context)
            context.coordinator.mapNotesCounter = mapNotes.count
        }
        
        guard isUserInteracting else { return }
        let thresholdWitness = ThresholdWitness(sensorThreshold: self.threshold)
        
        if pathPoints != context.coordinator.currentlyDisplayedPathPoints ||
            thresholdWitness != context.coordinator.currentThresholdWitness {
            drawPolyline(uiView, context: context)
            context.coordinator.currentlyDisplayedPathPoints = pathPoints
            context.coordinator.currentThresholdWitness = ThresholdWitness(sensorThreshold: threshold)
            context.coordinator.currentThreshold = threshold
            context.coordinator.drawHeatmap(uiView)
        }
        
        // MARK: Picker screen logic
        if placePickerIsUpdating {
            uiView.moveCamera(cameraUpdate)
            DispatchQueue.main.async {
                placePickerIsUpdating = false
            }
        }
        
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
        // MARK: - Picker screen logic
        if isMapOnPickerScreen {
            let location = placePickerLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            return GMSCameraUpdate.setTarget(location)
        }
        
        guard !pathPoints.isEmpty else {
            // We are not sure if this can ever happen
            let location = tracker.locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
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
        guard !isMapOnPickerScreen else {
            // MARK: - Picker screen logic
            let lat = tracker.locationManager.location?.coordinate.latitude ?? 37.35
            let long = tracker.locationManager.location?.coordinate.longitude ?? -122.05
            let newCameraPosition = GMSCameraPosition.camera(withLatitude: lat,
                                                             longitude: long,
                                                             zoom: 16)
            return newCameraPosition
        }
        
        // This get's overwritten anyway by camera update so setting starting point only makes sense if shouldAutoTrack is set to false (so when it's not a place picker screen)
        if let location = tracker.locationManager.location?.coordinate {
            let long = location.longitude
            let lat = location.latitude
            
            let newCameraPosition = GMSCameraPosition.camera(withLatitude: lat,
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
        guard let thresholds = threshold else { return .white }
        let formatter = Resolver.resolve(ThresholdFormatter.self, args: thresholds)
        let measurement = formatter.value(from: point.measurement)
        
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
    
    fileprivate func drawLastMeasurementPoint(_ dot: GMSMarker) {
        guard liveModeOn || isSessionFixed else {
            dot.map = nil
            return
        }
        
        guard let last = pathPoints.last else { return }
        
        let mainPoint = UIImage.imageWithColor(color: color(point: last), size: CGSize(width: Constants.Map.dotWidth, height: Constants.Map.dotHeight))
        dot.icon = mainPoint
    }
    
    func drawPolyline(_ uiView: GMSMapView, context: Context) {
        // Drawing the path
        let path = GMSMutablePath()
        let dot = context.coordinator.dot
        
        for point in pathPoints {
            let coordinate = point.location
            path.add(coordinate)
            
            dot.position = coordinate
            dot.map = uiView
        }
        
        drawLastMeasurementPoint(dot)
        
        let polyline = context.coordinator.polyline
        
        polyline.path = path
        polyline.strokeColor = .accentColor
        polyline.strokeWidth = CGFloat(Constants.Map.polylineWidth)
        polyline.map = uiView
    }
    
    func placeNotes(_ uiView: GMSMapView, notes: [MapNote], context: Context) {
        context.coordinator.noteMarkers.forEach { marker in
            marker.map = nil
        }
        context.coordinator.noteMarkers = []
        DispatchQueue.main.async {
            notes.forEach { note in
                let marker = GMSMarker()
                // 10 used here to be sure it will be on top of evertyhing
                marker.zIndex = 10
                let markerImage = note.markerImage
                let markerView = UIImageView(image: markerImage.withRenderingMode(.alwaysOriginal))
                marker.position = note.location
                marker.userData = note.id
                marker.iconView = markerView
                marker.map = uiView
                context.coordinator.noteMarkers.append(marker)
            }
        }
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, GMSMapViewDelegate {
        var parent: GoogleMapView!
        let polyline = GMSPolyline()
        let dot = GMSMarker()
        var currentlyDisplayedPathPoints = [PathPoint]()
        var currentThresholdWitness: ThresholdWitness?
        var currentThreshold: SensorThreshold?
        var heatmap: Heatmap? = nil
        var mapNotesCounter = 0
        var noteMarkers = [GMSMarker]()
        
        init(_ parent: GoogleMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            let lat = mapView.projection.coordinate(for: mapView.center).latitude
            let len = mapView.projection.coordinate(for: mapView.center).longitude
            
            // MARK: - Picker screen logic
            if parent.isMapOnPickerScreen {
                parent.placePickerLocation = CLLocationCoordinate2D(latitude: lat, longitude: len)
            }
            positionChanged(for: mapView)
            shouldAutoTrack = false
        }
        
        func mapView(_ mapView: GMSMapView, idleAt cameraPosition: GMSCameraPosition) {
            drawHeatmap(mapView)
        }
        
        func drawHeatmap(_ mapView: GMSMapView) {
            guard !parent.isSessionFixed else { return }
            
            let mapWidth = mapView.frame.width
            let mapHeight = mapView.frame.height
            
            guard mapWidth > 0, mapHeight > 0 else { return }
            
            heatmap?.remove()
            heatmap = nil
            
            guard let threshold = currentThreshold else { return }
            heatmap = Heatmap(mapView, sensorThreshold: threshold, mapWidth: Int(mapWidth), mapHeight: Int(mapHeight))
            heatmap?.drawHeatMap(pathPoints: currentlyDisplayedPathPoints)
        }
        
        func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
            centerMap(for: mapView)
            return true
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let userData = marker.userData as? Int {
                parent.noteNumber = userData
                parent.noteMarketTapped = true
            }
            return true
        }
        
        func centerMap(for mapView: GMSMapView) {
            guard !parent.isMapOnPickerScreen else {
                let lat = parent.tracker.locationManager.location?.coordinate.latitude ?? 37.35
                let long = parent.tracker.locationManager.location?.coordinate.longitude ?? -122.05
                let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 16)
                mapView.animate(to: camera)
                return
            }
            let lat = parent.liveModeOn ?
            parent.tracker.locationManager.location!.coordinate.latitude :
            parent.pathPoints.last?.location.latitude ?? 37.35
            let long = parent.liveModeOn ?
            parent.tracker.locationManager.location!.coordinate.longitude :
            parent.pathPoints.last?.location.longitude ?? -122.05
            
            let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 16)
            mapView.animate(to: camera)
        }
        
        private func positionChanged(for mapView: GMSMapView) {
            let visibleRegion = mapView.projection.visibleRegion()
            let bounds = GMSCoordinateBounds(region: visibleRegion)
            let visiblePathPoints = parent.pathPoints.filter { bounds.contains($0.location) }
            parent.onPositionChange?(visiblePathPoints)
        }
        
        lazy var shouldAutoTrack: Bool = !parent.isMapOnPickerScreen
        var myLocationSink: Any?
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
