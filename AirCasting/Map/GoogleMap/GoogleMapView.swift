//  Created by Lunar on 26/01/2021.
//

import UIKit
import SwiftUI
import GoogleMaps
import Resolver

struct GoogleMapView: UIViewRepresentable {
    @Injected private var tracker: LocationTracker
    
    @StateObject var butler: GoogleMapButler
    
    @Binding var isUserInteracting: Bool
    @Binding var noteMarketTapped: Bool
    @Binding var noteNumber: Int
    @Binding var mapNotes: [MapNote]
    @Binding var placePickerIsUpdating: Bool
    @Binding var placePickerLocation: CLLocationCoordinate2D?
    
    var liveModeOn: Bool
    var isSessionFixed: Bool
    
    let pathPoints: [PathPoint]
    let isMapOnPickerScreen: Bool
    
    private(set) var threshold: SensorThreshold?
    private var onPositionChange: (([PathPoint]) -> ())? = nil
    
    @Environment(\.colorScheme) var colorScheme
    
    init(pathPoints: [PathPoint],
         threshold: SensorThreshold? = nil,
         placePickerIsUpdating: Binding<Bool>,
         isUserInteracting: Binding<Bool>,
         isSessionActive: Bool = false,
         isSessionFixed: Bool = false,
         noteMarketTapped: Binding<Bool> = .constant(false),
         noteNumber: Binding<Int> = .constant(0),
         mapNotes: Binding<[MapNote]>,
         showMyLocationButton: Bool = true,
         isMapOnPickerScreen: Bool = false,
         placePickerLocation: Binding<CLLocationCoordinate2D?> = .constant(nil)) {

        self.pathPoints = pathPoints
        self.threshold = threshold
        self._placePickerIsUpdating = placePickerIsUpdating
        self._isUserInteracting = isUserInteracting
        self.liveModeOn = isSessionActive
        self.isSessionFixed = isSessionFixed
        self._noteMarketTapped = noteMarketTapped
        self._noteNumber = noteNumber
        self._mapNotes = mapNotes
        self.isMapOnPickerScreen = isMapOnPickerScreen
        self._placePickerLocation = placePickerLocation
        self._butler = .init(wrappedValue: .init(pathPoints: pathPoints,
                                                 isMapOnPickerScreen: isMapOnPickerScreen,
                                                 showMyLocationButton: showMyLocationButton,
                                                 placePickerLocation: placePickerLocation.wrappedValue))
    }
    
    /// Adds an action for when the map viewport is changed.
    /// - Parameter action: an action block that takes an array of currently visible `PathPoint`s.
    func onPositionChange(action: @escaping (_ visiblePoints: [PathPoint]) -> ()) -> Self {
        var newSelf = self
        newSelf.onPositionChange = action
        return newSelf
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        let mapView = butler.defineMakeUIVIew()
        butler.placeNotes(mapView, notes: mapNotes, context: context)
        butler.drawPolyline(mapView, context: context)
        
        mapView.delegate = context.coordinator
        context.coordinator.mapNotesCounter = mapNotes.count
        context.coordinator.myLocationSink = mapView.publisher(for: \.myLocation)
            .sink { [weak mapView] (location) in
                guard let coordinate = location?.coordinate else { return }
                mapView?.animate(toLocation: coordinate)
            }
        updateContextThresholdAndPathPoints(context: context)
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        if mapNotes.count != context.coordinator.mapNotesCounter {
            butler.placeNotes(uiView,
                              notes: mapNotes,
                              context: context)
            butler.drawPolyline(uiView,
                                context: context)
            context.coordinator.mapNotesCounter = mapNotes.count
        }
        
        butler.applyStylying(to: uiView)
        
        guard isUserInteracting else { return }
        let thresholdWitness = ThresholdWitness(sensorThreshold: self.threshold)
        
        if pathPoints != context.coordinator.currentlyDisplayedPathPoints ||
            thresholdWitness != context.coordinator.currentThresholdWitness {
            butler.drawPolyline(uiView, context: context)
            updateContextThresholdAndPathPoints(context: context)
            context.coordinator.drawHeatmap(uiView)
        }
        
        butler.defineMapType(uiView)

        // MARK: Picker screen logic
        if placePickerIsUpdating {
            uiView.moveCamera(butler.cameraUpdate)
            DispatchQueue.main.async {
                placePickerIsUpdating = false
            }
        }
        
        // Update camera's starting point
        guard context.coordinator.shouldAutoTrack else { return }
        DispatchQueue.main.async {
            uiView.moveCamera(butler.cameraUpdate)
            if uiView.camera.zoom > 16 {  uiView.animate(toZoom: 16) }
            // The zoom is set automatically somehow which results sometimes in 'too close' map
            // This helps us to fix it and still manage to fit into the 'bigger picture' if needed because of the long session
        }
    }
    
    func updateContextThresholdAndPathPoints(context: Context) {
        context.coordinator.currentlyDisplayedPathPoints = pathPoints
        context.coordinator.currentThresholdWitness = ThresholdWitness(sensorThreshold: threshold)
        context.coordinator.currentThreshold = threshold
    }
}

// MARK: Coordinator
extension GoogleMapView {
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
            if parent.isMapOnPickerScreen {
                parent.tracker.start()
            }
        }
        
        deinit {
            if parent.isMapOnPickerScreen {
                parent.tracker.stop()
            }
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
                let lat = parent.tracker.location.value?.coordinate.latitude ?? 37.35
                let long = parent.tracker.location.value?.coordinate.longitude ?? -122.05
                let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 16)
                mapView.animate(to: camera)
                return
            }
            
            let lat = parent.liveModeOn ?
            parent.tracker.location.value?.coordinate.latitude ?? 37.35 :
            parent.pathPoints.last?.location.latitude ?? 37.35
            let long = parent.liveModeOn ?
            parent.tracker.location.value?.coordinate.longitude ?? -122.05 :
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
