//  Created by Lunar on 26/01/2021.
//
import UIKit
import SwiftUI
import GoogleMaps
import Resolver

struct GoogleMapView: UIViewRepresentable {
    @ObservedObject private var butler: GoogleMapButler
    
    @Binding private var noteMarkerTapped: Bool
    @Binding private var noteNumber: Int
    
    private var mapPositioning: MapPositioning
    private var pathPoints: [PathPoint]
    
    private(set) var threshold: SensorThreshold?
    private var onPositionChange: (([PathPoint]) -> ())? = nil
    
    init(pathPoints: [PathPoint],
         threshold: SensorThreshold? = nil,
         isMyLocationEnabled: Bool = false,
         mapPositioning: MapPositioning = .init(),
         noteMarketTapped: Binding<Bool> = .constant(false),
         noteNumber: Binding<Int> = .constant(0),
         mapNotes: Binding<[MapNote]> = .constant([]),
         showMyLocationButton: Bool = true) {
        
        self.pathPoints = pathPoints
        self.threshold = threshold
        self.mapPositioning = mapPositioning
        self._noteMarkerTapped = noteMarketTapped
        self._noteNumber = noteNumber
        self._butler = .init(wrappedValue: .init(pathPoints: pathPoints,
                                                 showMyLocationButton: showMyLocationButton,
                                                 isMyLocationEnabled: isMyLocationEnabled,
                                                 mapPositioning: mapPositioning,
                                                 threshold: threshold,
                                                 notes: mapNotes))
    }
    
    /// Adds an action for when the map viewport is changed.
    /// - Parameter action: an action block that takes an array of currently visible `PathPoint`s.
    func onPositionChange(action: @escaping (_ visiblePoints: [PathPoint]) -> ()) -> Self {
        var newSelf = self
        newSelf.onPositionChange = action
        return newSelf
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        let mapView = butler.initialMakeUIVIew(context: context)
        
        mapView.delegate = context.coordinator
        context.coordinator.mapNotesCounter = butler.notes.count
        context.coordinator.myLocationSink = mapView.publisher(for: \.myLocation)
            .sink { [weak mapView] (location) in
                guard let coordinate = location?.coordinate else { return }
                mapView?.animate(toLocation: coordinate)
            }
        updateContextThresholdAndPathPoints(context: context)
        
        DispatchQueue.main.async {
            mapView.moveCamera(butler.cameraUpdate)
            if mapView.camera.zoom > 16 {  mapView.animate(toZoom: 16) }
            // Centers the user onto last recorded position
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        context.coordinator.butler = butler
        butler.applyStylying(to: uiView)
        if butler.notesNumber != context.coordinator.mapNotesCounter {
            butler.placeNotes(uiView, context: context)
            butler.drawPolyline(uiView,context: context)
            context.coordinator.mapNotesCounter = butler.notesNumber
        }
        
        let thresholdWitness = ThresholdWitness(sensorThreshold: self.threshold)
        
        if pathPoints != context.coordinator.currentlyDisplayedPathPoints ||
            thresholdWitness != context.coordinator.currentThresholdWitness {
            butler.drawPolyline(uiView, context: context)
            updateContextThresholdAndPathPoints(context: context)
            context.coordinator.drawHeatmap(uiView)
        }
    }
    
    private func updateContextThresholdAndPathPoints(context: Context) {
        context.coordinator.currentlyDisplayedPathPoints = pathPoints
        context.coordinator.currentThresholdWitness = ThresholdWitness(sensorThreshold: threshold)
        context.coordinator.currentThreshold = threshold
    }
}

// MARK: Coordinator
extension GoogleMapView {
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, butler: butler)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, GMSMapViewDelegate {
        var parent: GoogleMapView!
        var butler: GoogleMapButler!
        var currentlyDisplayedPathPoints = [PathPoint]()
        var currentThresholdWitness: ThresholdWitness?
        var currentThreshold: SensorThreshold?
        var heatmap: Heatmap? = nil
        var mapNotesCounter = 0
        var noteMarkers = [GMSMarker]()
        var myLocationSink: Any?
        
        let polyline = GMSPolyline()
        let dot = GMSMarker()
        
        init(_ parent: GoogleMapView, butler: GoogleMapButler) {
            self.parent = parent
            self.butler = butler
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            positionChanged(for: mapView)
        }
        
        func mapView(_ mapView: GMSMapView, idleAt cameraPosition: GMSCameraPosition) {
            drawHeatmap(mapView)
        }
        
        func drawHeatmap(_ mapView: GMSMapView) {
            guard !parent.mapPositioning.fixed else { return }
            
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
                parent.noteMarkerTapped = true
            }
            return true
        }
        
        private func centerMap(for mapView: GMSMapView) {
            let location = butler.optionalTrackerLocation()
            
            let lat = parent.mapPositioning.live ? location.0 : parent.pathPoints.last?.location.latitude ?? 37.35
            let long = parent.mapPositioning.live ? location.1 : parent.pathPoints.last?.location.longitude ?? -122.05
            
            let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 16)
            mapView.animate(to: camera)
        }
        
        private func positionChanged(for mapView: GMSMapView) {
            let visibleRegion = mapView.projection.visibleRegion()
            let bounds = GMSCoordinateBounds(region: visibleRegion)
            let visiblePathPoints = parent.pathPoints.filter { bounds.contains($0.location) }
            parent.onPositionChange?(visiblePathPoints)
        }
    }
}
