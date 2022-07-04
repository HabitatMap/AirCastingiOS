// Created by Lunar on 23/03/2022.
//

import UIKit
import SwiftUI
import GoogleMaps
import GooglePlaces
import Resolver

struct CreatingSessionMapView: UIViewRepresentable {
    
    typealias UIViewType = GMSMapView
    var isMyLocationEnabled = false
    var startingLocation: CLLocationCoordinate2D?
    
    init(isMyLocationEnabled: Bool = false, startingLocation: CLLocationCoordinate2D? = nil) {
        self.isMyLocationEnabled = isMyLocationEnabled
        self.startingLocation = startingLocation
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        let location = context.coordinator.tracker.location.value
        if location == nil {
            Log.error("Location not found on makeUIView()!")
        }
        
        let latitude = (isMyLocationEnabled ? location?.coordinate.latitude : startingLocation?.latitude) ?? 37.35
        let longitude = (isMyLocationEnabled ? location?.coordinate.longitude :
                            startingLocation?.longitude) ?? -122.05
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        
        mapView.settings.myLocationButton = isMyLocationEnabled
        mapView.isMyLocationEnabled = isMyLocationEnabled

        do {
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                Log.error("Unable to find style.json")
            }
        } catch {
            Log.error("One or more of the map styles failed to load. \(error)")
        }
        
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        //
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, GMSMapViewDelegate {
        var parent: CreatingSessionMapView!
        @Injected var tracker: LocationTracker
        
        init(_ parent: CreatingSessionMapView) {
            self.parent = parent
            super.init()
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            let latitude = mapView.camera.target.latitude
            let longitude = mapView.camera.target.longitude
            
            let mapCamera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16)
            mapView.camera = mapCamera
        }
        
        func centerMap(for mapView: GMSMapView) {
            let lat = tracker.location.value?.coordinate.latitude ?? 37.35
            let long = tracker.location.value?.coordinate.longitude ?? -122.05
            
            let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 16)
            mapView.animate(to: camera)
        }
        
        func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
            centerMap(for: mapView)
            return true
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

