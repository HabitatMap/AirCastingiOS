// Created by Lunar on 28/02/2022.
//

import UIKit
import SwiftUI
import GoogleMaps
import Resolver
import Combine

struct SearchAndFollowMap: UIViewRepresentable {
    @InjectedObject private var userSettings: UserSettings
    typealias UIViewType = GMSMapView
    @Binding var startingPoint: CLLocationCoordinate2D
    @Binding var showSearchAgainButton: Bool
    @Binding var sessions: [MapSessionMarker]
    @Binding var selectedPointerID: PointerValue
    private var onPositionChangeAction: ((GeoSquare) -> ())? = nil
    private var onMarkerChangeAction: ((Int) -> ())? = nil
    private var onStartingLocationAction: ((GeoSquare) -> ())? = nil
    @State var startingPointChanged = false
    
    init(startingPoint: Binding<CLLocationCoordinate2D>, showSearchAgainButton: Binding<Bool>, sessions: Binding<[MapSessionMarker]>, selectedPointerID: Binding<PointerValue>) {
        self._startingPoint = .init(projectedValue: startingPoint)
        self._showSearchAgainButton = .init(projectedValue: showSearchAgainButton)
        self._sessions = .init(projectedValue: sessions)
        self._selectedPointerID = .init(projectedValue: selectedPointerID)
    }
    
    /// Adds an action for when the map viewport is changed.
    /// - Parameter action: an action block that takes an array of currently visible `GeoSquare`s.
    func onPositionChange(action: @escaping (_ geoSquare: GeoSquare) -> ()) -> Self {
        var newSelf = self
        newSelf.onPositionChangeAction = action
        return newSelf
    }
    
    func onMarkerChange(action: @escaping (_ pointer: Int) -> ()) -> Self {
        var newSelf = self
        newSelf.onMarkerChangeAction = action
        return newSelf
    }
    
    func onStartingLocationChange(action: @escaping (GeoSquare) -> ()) -> Self {
        var newSelf = self
        newSelf.onStartingLocationAction = action
        return newSelf
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        context.coordinator.startingPointHolder = self.startingPoint
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
        if userSettings.satteliteMap { mapView.mapType = .satellite }
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        if (startingPoint.latitude, startingPoint.longitude) != (context.coordinator.startingPointHolder.latitude, context.coordinator.startingPointHolder.longitude) {
            DispatchQueue.main.async { startingPointChanged = true }
            uiView.animate(to: GMSCameraPosition(latitude: startingPoint.latitude, longitude: startingPoint.longitude, zoom: 10))
        }
        if selectedPointerID.number != context.coordinator.pointerIdHolder.number {
            context.coordinator.selectNewPointer(newid: selectedPointerID.number, oldid: context.coordinator.pointerIdHolder.number)
            context.coordinator.pointerIdHolder = selectedPointerID
        } else if !showSearchAgainButton && selectedPointerID == .noValue && context.coordinator.sessionKeeper != sessions {
            placeDots(uiView, context: context)
            context.coordinator.sessionKeeper = sessions
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
                let markerImage = session.markerImage
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
        var pointerIdHolder: PointerValue = .noValue
        var startingPointHolder: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 20, longitude: 20)
        var sessionKeeper: [MapSessionMarker]? = nil
        
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
        }
        
        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            if parent.startingPointChanged {
                startPositionShouldChange(for: mapView)
            } else {
                dotsPositionShouldChange(for: mapView)
            }
            DispatchQueue.main.async { self.parent.startingPointChanged = false }
            parent.startingPoint = CLLocationCoordinate2D(latitude: mapView.camera.target.latitude, longitude: mapView.camera.target.longitude)
            startingPointHolder = parent.startingPoint
        }
        
        
        func selectNewPointer(newid: Int, oldid: Int) {
            DispatchQueue.main.async {
                self.sessionSearched.forEach { m in
                    guard let marker = m.userData as? Int else {
                        Log.error("Unexpectedly found value other than Int in marker userData")
                        assertionFailure()
                        return
                    }
                    if marker == newid {
                        let markerImage = UIImage(systemName: "circle.circle.fill")!.scalePreservingAspectRatio(targetSize: CGSize(width: 35, height: 35))
                        m.iconView = self.adjustMarkerImage(with: markerImage)
                    } else if marker == oldid {
                        let markerImage = UIImage(systemName: "circle.circle.fill")!
                        m.iconView = self.adjustMarkerImage(with: markerImage)
                    }
                }
            }
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            guard let newPointerID = marker.userData as? Int else {
                Log.error("Unexpectedly found value other than Int in marker userData")
                assertionFailure()
                return true
            }
            parent.onMarkerChangeAction?(newPointerID)
            return true
        }
        
        func getGeoCoordinates(for mapView: GMSMapView) -> GeoSquare {
            let NW = (mapView.projection.visibleRegion().farLeft.latitude, mapView.projection.visibleRegion().farLeft.longitude)
            let SE = (mapView.projection.visibleRegion().nearRight.latitude, mapView.projection.visibleRegion().nearRight.longitude)
            return GeoSquare(north: NW.0, south: SE.0, east: SE.1, west: NW.1)
        }
        
        private func adjustMarkerImage(with image: UIImage) -> UIImageView {
            return UIImageView(image: image.withRenderingMode(.alwaysTemplate))
        }
        
        private func startPositionShouldChange(for mapView: GMSMapView) {
            let coordinates = getGeoCoordinates(for: mapView)
            parent.onStartingLocationAction?(GeoSquare(north: coordinates.north, south: coordinates.south, east: coordinates.east, west: coordinates.west))
        }
        
        private func dotsPositionShouldChange(for mapView: GMSMapView) {
            let coordinates = getGeoCoordinates(for: mapView)
            parent.onPositionChangeAction?(GeoSquare(north: coordinates.north, south: coordinates.south, east: coordinates.east, west: coordinates.west))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
