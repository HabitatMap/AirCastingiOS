// Created by Lunar on 27/07/2022.
//
import SwiftUI
import GoogleMaps
import Resolver

protocol GoogleMapCore {
    func setStartingPointAndInitGMSMap() -> GMSMapView 
    func applyJSONStylying(to mapView: GMSMapView)
    func optionalTrackerLocation() -> (Double, Double)
    func defineMapType(_ uiView: GMSMapView)
    func getLocationForEmptyPathPoints() -> CLLocationCoordinate2D
}

struct GoogleMapCoreDefault: GoogleMapCore {
    @Injected private var tracker: LocationTracker
    @InjectedObject private var userSettings: UserSettings
    var isLightMode: Bool { UITraitCollection.current.userInterfaceStyle == .light }
    
    func setStartingPointAndInitGMSMap() -> GMSMapView {
        let startingPoint = setStartingPoint()
        let mapView = GMSMapView.map(withFrame: .zero, camera: startingPoint)
        applyJSONStylying(to: mapView)
        defineMapType(mapView)
        return mapView
    }
    
    func applyJSONStylying(to mapView: GMSMapView) {
        do {
            if let styleURL = Bundle.main.url(forResource: isLightMode ? "style" : "darkStyle", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                Log.error("Unable to find style.json")
            }
        } catch {
            Log.error("One or more of the map styles failed to load. \(error)")
        }
    }
    
    func optionalTrackerLocation() -> (Double, Double) {
        let lat = tracker.location.value?.coordinate.latitude ?? 37.35
        let long = tracker.location.value?.coordinate.longitude ?? -122.05
        return (lat, long)
    }
    
    func defineMapType(_ uiView: GMSMapView) {
        if userSettings.satteliteMap { uiView.mapType = .hybrid } else { uiView.mapType = .normal }
    }
    
    func getLocationForEmptyPathPoints() -> CLLocationCoordinate2D {
        return tracker.location.value?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    
    private func setStartingPoint() -> GMSCameraPosition {
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
