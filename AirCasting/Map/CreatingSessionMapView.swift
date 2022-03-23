// Created by Lunar on 23/03/2022.
//

import UIKit
import SwiftUI
import GoogleMaps
import GooglePlaces
import Resolver

struct CreatingSessionMapView: UIViewRepresentable {
    
    typealias UIViewType = GMSMapView
    @InjectedObject private var tracker: LocationTracker
    var isMyLocationEnabled = false
    
    init(isMyLocationEnabled: Bool = false) {
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        self.isMyLocationEnabled = isMyLocationEnabled
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        let latitude = tracker.locationManager.location?.coordinate.latitude ?? 37.35
        let longitude = tracker.locationManager.location?.coordinate.longitude ?? -122.05
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        
        mapView.settings.myLocationButton = true
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
        
        init(_ parent: CreatingSessionMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            let latitude = mapView.camera.target.latitude
            let longitude = mapView.camera.target.longitude
            
            let mapCamera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16)
            mapView.camera = mapCamera
        }
        
        func centerMap(for mapView: GMSMapView) {
            let lat = parent.tracker.locationManager.location?.coordinate.latitude ?? 37.35
            let long = parent.tracker.locationManager.location?.coordinate.longitude ?? -122.05
            
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

