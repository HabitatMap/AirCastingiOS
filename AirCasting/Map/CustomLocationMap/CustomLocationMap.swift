//  Created by Lunar on 26/01/2021.
//

import UIKit
import SwiftUI
import GoogleMaps
import Resolver

struct CustomLocationMap: UIViewRepresentable {
    @Injected private var tracker: LocationTracker
    
    @ObservedObject private var butler: CustomLocationButler
    
    @Binding private var placePickerIsUpdating: Bool
    @Binding private var placePickerLocation: CLLocationCoordinate2D?
    
    init(placePickerIsUpdating: Binding<Bool>,
         placePickerLocation: Binding<CLLocationCoordinate2D?>) {
        self._placePickerIsUpdating = placePickerIsUpdating
        self._placePickerLocation = placePickerLocation
        self._butler = .init(wrappedValue: .init(placePickerLocation: placePickerLocation))
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        let mapView = butler.initialMakeUIVIew()
        mapView.settings.myLocationButton = true
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        context.coordinator.butler = butler
        
        if placePickerIsUpdating {
            uiView.moveCamera(butler.cameraUpdate)
            DispatchQueue.main.async { placePickerIsUpdating = false }
        }
    }
}

// MARK: Coordinator
extension CustomLocationMap {
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, butler: butler)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, GMSMapViewDelegate {
        var parent: CustomLocationMap!
        var butler: CustomLocationButler!
        
        init(_ parent: CustomLocationMap, butler: CustomLocationButler) {
            self.parent = parent
            self.butler = butler
            parent.tracker.start()
        }
        
        deinit {
            parent.tracker.stop()
        }
        
        func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
            centerMap(for: mapView)
            return true
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            let lat = mapView.projection.coordinate(for: mapView.center).latitude
            let len = mapView.projection.coordinate(for: mapView.center).longitude
            
            parent.placePickerLocation = CLLocationCoordinate2D(latitude: lat, longitude: len)
        }
        
        private func centerMap(for mapView: GMSMapView) {
            let location = butler.optionalTrackerLocation()
            let camera = GMSCameraPosition.camera(withLatitude: location.0, longitude: location.1, zoom: 16)
            mapView.animate(to: camera)
        }
    }
}
