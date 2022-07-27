// Created by Lunar on 27/07/2022.
//

import Foundation
import SwiftUI
import GoogleMaps
import Resolver

// TODO: Think deeply about Context and if we should be passing it here.

class GoogleMapButler: ObservableObject {
    @Injected private var tracker: LocationTracker
    @InjectedObject private var userSettings: UserSettings
    
    private let coreMap = GoogleMapCoreDefault()
    
    let pathPoints: [PathPoint]
    let isMapOnPickerScreen: Bool
    let showMyLocationButton: Bool
    var isMyLocationEnabled: Bool
    var liveModeOn: Bool
    var isSessionFixed: Bool
    private(set) var threshold: SensorThreshold?
    var placePickerLocation: CLLocationCoordinate2D?
    
    init(pathPoints: [PathPoint],
         isMapOnPickerScreen: Bool,
         showMyLocationButton: Bool,
         isMyLocationEnabled: Bool = false,
         isSessionActive: Bool = false,
         isSessionFixed: Bool = false,
         threshold: SensorThreshold? = nil,
         placePickerLocation: CLLocationCoordinate2D?) {
        
        self.pathPoints = pathPoints
        self.isMapOnPickerScreen = isMapOnPickerScreen
        self.showMyLocationButton = showMyLocationButton
        self.isMyLocationEnabled = isMyLocationEnabled
        self.threshold = threshold
        self.liveModeOn = isSessionActive
        self.isSessionFixed = isSessionFixed
        self.placePickerLocation = placePickerLocation
    }
    
    func defineMakeUIVIew() -> GMSMapView {
        let startingPoint = setStartingPoint(points: pathPoints)
        let mapView = GMSMapView.map(withFrame: .zero, camera: startingPoint)
        mapView.settings.myLocationButton = showMyLocationButton
        // place notes
        coreMap.apllyStylying(to: mapView)
        if userSettings.satteliteMap { mapView.mapType = .hybrid }
        // draw polyline
        mapView.isMyLocationEnabled = isMyLocationEnabled
        return mapView
    }
    
    func applyStylying(to mapView: GMSMapView) {
        coreMap.apllyStylying(to: mapView)
    }
    
    func defineMapType(_ uiView: GMSMapView) {
        if userSettings.satteliteMap { uiView.mapType = .hybrid } else { uiView.mapType = .normal }
    }
    
    func placeNotes(_ uiView: GMSMapView, notes: [MapNote], context: UIViewRepresentableContext<GoogleMapView>) {
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
    
    func drawPolyline(_ uiView: GMSMapView, context: UIViewRepresentableContext<GoogleMapView>) {
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
    
    fileprivate func drawLastMeasurementPoint(_ dot: GMSMarker) {
        guard liveModeOn || isSessionFixed else {
            dot.map = nil
            return
        }
        
        guard let last = pathPoints.last else { return }
        
        let mainPoint = UIImage.imageWithColor(color: color(point: last), size: CGSize(width: Constants.Map.dotWidth, height: Constants.Map.dotHeight))
        dot.icon = mainPoint
    }
    
    func color(point: PathPoint) -> UIColor {
        guard let thresholds = threshold else { return .white }
        let formatter = Resolver.resolve(ThresholdFormatter.self, args: thresholds)
        let measurement = formatter.value(from: point.measurement)
        
        return Self.color(value: measurement, threshold: thresholds)
    }
    
    var cameraUpdate: GMSCameraUpdate {
        // MARK: - Picker screen logic
        if isMapOnPickerScreen {
            let location = placePickerLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            return GMSCameraUpdate.setTarget(location)
        }
        
        guard !pathPoints.isEmpty else {
            // We are not sure if this can ever happen
            let location = tracker.location.value?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
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
    
    
    private func setStartingPoint(points: [PathPoint]) -> GMSCameraPosition {
        guard !isMapOnPickerScreen else {
            // MARK: - Picker screen logic
            let lat = tracker.location.value?.coordinate.latitude ?? 37.35
            let long = tracker.location.value?.coordinate.longitude ?? -122.05
            let newCameraPosition = GMSCameraPosition.camera(withLatitude: lat,
                                                             longitude: long,
                                                             zoom: 16)
            return newCameraPosition
        }
        
        // This get's overwritten anyway by camera update so setting starting point only makes sense if shouldAutoTrack is set to false (so when it's not a place picker screen)
        if let location = tracker.location.value?.coordinate {
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
}
