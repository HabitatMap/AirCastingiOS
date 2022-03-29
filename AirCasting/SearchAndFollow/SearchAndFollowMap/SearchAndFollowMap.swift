// Created by Lunar on 28/02/2022.
//

import UIKit
import SwiftUI
import GoogleMaps
import Resolver
import Combine

struct SearchAndFollowMap: UIViewRepresentable {
    
    typealias UIViewType = GMSMapView
    var startingPoint: CLLocationCoordinate2D
    @Binding var showSearchAgainButton: Bool
    @Binding var sessions: [MapSessionMarker]
    @State var markerWasTapped: Bool = false
    @Binding var pointerID: Int
    private var onPositionChangeAction: ((GeoSquare) -> ())? = nil
    
    init(startingPoint: CLLocationCoordinate2D, showSearchAgainButton: Binding<Bool>, sessions: Binding<[MapSessionMarker]>, pointerID: Binding<Int>) {
        self.startingPoint = startingPoint
        self._showSearchAgainButton = .init(projectedValue: showSearchAgainButton)
        self._sessions = .init(projectedValue: sessions)
        self._pointerID = .init(projectedValue: pointerID)
    }
    
    /// Adds an action for when the map viewport is changed.
    /// - Parameter action: an action block that takes an array of currently visible `GeoSquare`s.
    func onPositionChange(action: @escaping (_ geoSquare: GeoSquare) -> ()) -> Self {
        var newSelf = self
        newSelf.onPositionChangeAction = action
        return newSelf
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        let startingPoint = setStartingPoint(using: startingPoint)
        let mapView = GMSMapView.map(withFrame: .zero,
                                     camera: startingPoint)

        placeDots(mapView, context: context)
        
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
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        if pointerID != context.coordinator.pointerIdHolder {
            context.coordinator.pointerIdHolder = pointerID
            placeDots(uiView, context: context)
        }
        if !showSearchAgainButton {
            placeDots(uiView, context: context)
        }
    }
    
    func setStartingPoint(using point: CLLocationCoordinate2D) -> GMSCameraPosition {
            let long = point.longitude
            let lat = point.latitude
            let newCameraPosition = GMSCameraPosition.camera(withLatitude: lat,
                                                              longitude: long,
                                                              zoom: 10)
            return newCameraPosition
    }
    
    func placeDots(_ uiView: GMSMapView, context: Context) {
        context.coordinator.sessionSearched.forEach { marker in
            marker.map = nil
        }
        context.coordinator.sessionSearched = []
        DispatchQueue.main.async {
            sessions.forEach { session in
                let marker = GMSMarker()
                let markerImage = ((session.id == pointerID) ? session.markerImage.scalePreservingAspectRatio(targetSize: CGSize(width: 35, height: 35)) : session.markerImage)
                let markerView = UIImageView(image: markerImage.withRenderingMode(.alwaysTemplate))
                markerView.tintColor = .accentColor
                marker.position = session.location
                marker.userData = session.id
                marker.iconView = markerView
                marker.map = uiView
                context.coordinator.sessionSearched.append(marker)
            }
        }
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, GMSMapViewDelegate {
        var parent: SearchAndFollowMap!
        var sessionSearched = [GMSMarker]()
        var pointerIdHolder: Int = -1
        
        init(_ parent: SearchAndFollowMap) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            if position.zoom < 6 {
                // Prevents user from zooming out to much, as it can results in bad UX expereince
                // The reason is a lot of data which can be downloaded
                let latitude = mapView.camera.target.latitude
                let longitude = mapView.camera.target.longitude
                
                let mapCamera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 6)
                mapView.camera = mapCamera
                
            }
            parent.startingPoint = CLLocationCoordinate2D(latitude: mapView.camera.target.latitude, longitude: mapView.camera.target.longitude)
            dotsPositionShouldChange(for: mapView)
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            self.parent.pointerID = marker.userData as! Int
            self.parent.markerWasTapped = true
            return true
        }
        
        private func dotsPositionShouldChange(for mapView: GMSMapView) {
            let NW = (mapView.projection.visibleRegion().farLeft.latitude, mapView.projection.visibleRegion().farLeft.longitude)
            let SE = (mapView.projection.visibleRegion().nearRight.latitude, mapView.projection.visibleRegion().nearRight.longitude)
            parent.onPositionChangeAction?(GeoSquare(north: NW.0, south: SE.0, east: SE.1, west: NW.1))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
