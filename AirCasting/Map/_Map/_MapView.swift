// Created by Lunar on 09/09/2022.
//

import UIKit
import SwiftUI
import GoogleMaps
import Combine

protocol MapLocationTracker {
    func startTrackingUserPosition(_ newPos: @escaping (CLLocation) -> Void) -> MapLocationTrackerStoper
    func getLastKnownLocation() -> CLLocation?
    
}

protocol MapLocationTrackerStoper {
    func stopTrackingUserPosition()
}

extension _MapView {
    enum MapType {
        case normal
        case satellite
        case terrain
        case hybrid
    }
    
    enum TrackingStyle { // Camera
        case none // camera still
        case user // camera centered on user position
        case latestPathPoint // camera centerd on latest path point
        case wholePath // camera centerd on the center of the path
    }
    
    enum UserIndicatorStyle {
        case none // no dot
        case standard // google style dot
        case custom(color: UIColor) // AC color dot
    }
    
    struct PathPoint: Equatable {
        let lat: Double
        let long: Double
        let value: Double
    }
    
    struct Styling {
        let polylineWidth: Int
        let customDotRadius: Int
    }
    
    struct Marker: Equatable {
        let id: Int
        let image: UIImage
        let location: CLLocation
        let handler: (() -> Void)?
        
        static func == (lhs: _MapView.Marker, rhs: _MapView.Marker) -> Bool {
            lhs.id == rhs.id
        }
    }
}

extension _MapView {
    class Coordinator {
        fileprivate var latestUserLocation: CLLocation?
        fileprivate var polyline = GMSPolyline()
        fileprivate var currentPath: [PathPoint] = []
        fileprivate var customUserMarker: GMSMarker?
        fileprivate var myLocationSink: Any?
        fileprivate var mapViewDelegateHandler: MapViewDelegateHandler?
        fileprivate var suspendTracking: Bool = false
        fileprivate var gmsMarkers: [GMSMarker] = []
        fileprivate var previousFrameMarkers: [Marker] = []
        fileprivate var trackingToken: MapLocationTrackerStoper?
    }
}

struct _MapView: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    
    private let path: [PathPoint]
    private let type: MapType
    private let trackingStyle: TrackingStyle
    private let myLocationButtonBehavior: TrackingStyle
    private let userIndicatorStyle: UserIndicatorStyle
    private let locationTracker: MapLocationTracker
    private let markers: [Marker]
    private let stickHardToTheUser: Bool
    private var overlayClosure: ((GMSMapView) -> Void)?
    private var mapDidChangePosition: ((CLLocation) -> Void)?
    private var myLocationHandler: (() -> Void)?
    
    init(path: [PathPoint] = [], type: MapType, trackingStyle: TrackingStyle, myLocationButtonBehavior: TrackingStyle? = nil, userIndicatorStyle: UserIndicatorStyle, locationTracker: MapLocationTracker, markers: [Marker] = [], stickHardToTheUser: Bool = false) {
        self.path = path
        self.type = type
        self.trackingStyle = trackingStyle
        self.myLocationButtonBehavior = myLocationButtonBehavior ?? trackingStyle
        self.userIndicatorStyle = userIndicatorStyle
        self.locationTracker = locationTracker
        self.markers = markers
        self.stickHardToTheUser = stickHardToTheUser
    }
    
    // This is part of a hack that allows us to stich heatmap mechanism
    // into this new map.
    func addingOverlay(_ closure: @escaping (GMSMapView) -> Void) -> Self {
        var mutableSelf = self
        mutableSelf.overlayClosure = closure
        return mutableSelf
    }
    
    func indicateMapLocationChange(_ closure: @escaping (CLLocation) -> Void) -> Self {
        var mutableSelf = self
        mutableSelf.mapDidChangePosition = closure
        return mutableSelf
    }
    
    func onMyLocationButtonTapped(_ closure: @escaping () -> Void) -> Self {
        var mutableSelf = self
        mutableSelf.myLocationHandler = closure
        return mutableSelf
    }
    
    
    func makeUIView(context: Context) -> GMSMapView {
        let startingPoint = getStartingPoint(coordinator: context.coordinator)
        let mapView = GMSMapView(frame: .zero, camera: startingPoint)
        setupMyLocationButtonVisibility(for: mapView)
        mapView.mapType = type.gmsMapviewType
        
        setupMapDelegate(in: mapView, coordinator: context.coordinator)
        
        if isUserPositionTrackingRequired {
            context.coordinator.trackingToken = locationTracker.startTrackingUserPosition { [weak coord = context.coordinator] location in
                coord?.latestUserLocation = location
                if stickHardToTheUser { context.coordinator.suspendTracking = false }
            }
        }
        
        setupStyling(for: mapView)
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        overlayClosure?(uiView)
        let coordinator = context.coordinator
        setupUserIndicatorStyle(with: userIndicatorStyle, in: uiView, with: coordinator)
        if markers != coordinator.previousFrameMarkers {
            placeMarkers(uiView, markers: markers, coordinator: coordinator)
            coordinator.previousFrameMarkers = markers
        }
        if coordinator.currentPath != path {
            drawPolyline(uiView, coordinator: coordinator)
            coordinator.currentPath = path
        }
        setupStyling(for: uiView)
        
        guard !coordinator.suspendTracking else { return }
        updateCameraPosition(in: uiView, coordinator: coordinator)
    }
    
    private func setupMyLocationButtonVisibility(for mapView: GMSMapView) {
        guard case (.none, .none) = (trackingStyle, userIndicatorStyle) else {
            mapView.settings.myLocationButton = true; return
        }
        mapView.settings.myLocationButton = false
    }
    
    private func setupMapDelegate(in mapView: GMSMapView, coordinator: Coordinator) {
        coordinator.mapViewDelegateHandler = MapViewDelegateHandler(myLocationTapHandler: {
            handleLocationButtonTapped(in: $0, coordinator: coordinator)
            return true
        }, draggingHandler: { _ in
            coordinator.suspendTracking = true
        }, markerTapHandler: { mapView, marker in
            let marker = coordinator.previousFrameMarkers.first(where: { $0.id == (marker.userData as? Int) })
            marker?.handler?()
            return marker?.handler != nil
        }, idleAt: { mapView, location in
            overlayClosure?(mapView)
        }, didChangePosition: { position in
            mapDidChangePosition?(.init(latitude: position.target.latitude,
                                       longitude: position.target.longitude))
        })
        
        mapView.delegate = coordinator.mapViewDelegateHandler
    }
    
    private func placeMarkers(_ uiView: GMSMapView, markers: [Marker], coordinator: Coordinator) {
        clearMarkers(in: coordinator)
        coordinator.gmsMarkers = markers.map { createMarker(from: $0, in: uiView) }
    }
    
    private func clearMarkers(in coordinator: Coordinator) {
        coordinator.gmsMarkers.forEach { marker in
            marker.map = nil
        }
        coordinator.gmsMarkers = []
    }
    
    private func createMarker(from marker: Marker, in uiView: GMSMapView) -> GMSMarker {
        let gmsMarker = GMSMarker()
        // 10 used here to be sure it will be on top of evertyhing
        gmsMarker.zIndex = 10
        let markerImage = marker.image
        let markerView = UIImageView(image: markerImage.withRenderingMode(.alwaysOriginal))
        gmsMarker.position = marker.location.coordinate
        gmsMarker.userData = marker.id
        gmsMarker.iconView = markerView
        gmsMarker.map = uiView
        return gmsMarker
    }
    
    private func updateCameraPosition(in view: GMSMapView, coordinator: Coordinator) {
        switch trackingStyle {
        case .latestPathPoint:
            centerMapOnLatestPathPoint(in: view, coordinator: coordinator)
        case .none:
            break
        case .wholePath:
            centerMapOnWholePath(in: view, coordinator: coordinator)
        case .user:
            centerMapOnUserPosition(in: view, coordinator: coordinator)
        }
    }
    
    private func handleLocationButtonTapped(in view: GMSMapView, coordinator: Coordinator) {
        coordinator.suspendTracking = false
        guard let myLocationHandler else {
            defaultMyLocationButtonBehavior(in: view, coordinator: coordinator)
            return
        }
        myLocationHandler()
    }
    
    private func defaultMyLocationButtonBehavior(in view: GMSMapView, coordinator: Coordinator) {
        switch myLocationButtonBehavior {
        case .none:
            centerMapOnUserPosition(in: view, coordinator: coordinator)
        case .user:
            centerMapOnUserPosition(in: view, coordinator: coordinator)
        case .latestPathPoint:
            centerMapOnLatestPathPoint(in: view, coordinator: coordinator)
        case .wholePath:
            centerMapOnWholePath(in: view, coordinator: coordinator)
        }
    }
    
    private func centerMapOnUserPosition(in view: GMSMapView, coordinator: Coordinator) {
        guard let latestUserLocation = coordinator.latestUserLocation else { return }
        let userPos = GMSCameraPosition(target: latestUserLocation.coordinate, zoom: 16.0)
        view.animate(to: userPos)
    }
    
    private func centerMapOnLatestPathPoint(in view: GMSMapView, coordinator: Coordinator) {
        guard let lastPathPoint = path.last else { return }
        let userPos = GMSCameraPosition(target: .init(latitude: lastPathPoint.lat, longitude: lastPathPoint.long), zoom: 16.0)
        view.animate(to: userPos)
    }
    
    private func centerMapOnWholePath(in view: GMSMapView, coordinator: Coordinator) {
        guard isMapVisibleOnTheScreen(view: view) else { return }
        
        if !allPointWithinBounds(view: view) {
            centerWithinPathBounds(view: view)
        }
    }
    
    private func isMapVisibleOnTheScreen(view: GMSMapView) -> Bool {
        // There is a point in time, when the map is not yet available on the screen,
        // this happens, along with the initialization.
        // When this happens, every point of visible region is set to -180.0.
        let visibleRegion = view.projection.visibleRegion()
        return (visibleRegion.farLeft != .init(latitude: -180, longitude: -180) ||
                visibleRegion.nearLeft != .init(latitude: -180, longitude: -180) ||
                visibleRegion.farRight != .init(latitude: -180, longitude: -180) ||
                visibleRegion.nearRight != .init(latitude: -180, longitude: -180))
    }

    
    private func allPointWithinBounds(view: GMSMapView) -> Bool {
        let visibleRegion = view.projection.visibleRegion()
        return path.allSatisfy({ GMSCoordinateBounds(region: visibleRegion).contains(.init(latitude: $0.lat,
                                                                                           longitude: $0.long)) })
    }
    
    private func centerWithinPathBounds(view: GMSMapView) {
        let initialBounds = GMSCoordinateBounds()
        let pathPointsBoundingBox = path.reduce(initialBounds) { bounds, point in
            bounds.includingCoordinate(.init(latitude: point.lat, longitude: point.long))
        }
        let cameraUpdate = GMSCameraUpdate.fit(pathPointsBoundingBox, withPadding: 1.0)
        view.moveCamera(cameraUpdate)
        if view.camera.zoom > 16.0 {
            view.moveCamera(GMSCameraUpdate.zoom(to: 16.0))
        }
    }
    
    private var isUserPositionTrackingRequired: Bool {
        switch (trackingStyle, userIndicatorStyle) {
        case (.user, _): return true
        case (_, .custom): return true
        // NOTE: for (_, .standard) case we don't need to track the user because GMSMapView can take care of that for us
        default: return false
        }
    }
    
    private func setupUserIndicatorStyle(with style: UserIndicatorStyle, in view: GMSMapView, with coordinator: Coordinator) {
        guard let userLocation = coordinator.latestUserLocation else { return }
        switch style {
        case .none:
            break
        case .standard:
            view.isMyLocationEnabled = true
        case .custom(let color):
            createCustomUserIndicator(color: color, userLocation: userLocation, uiView: view, coordinator: coordinator)
        }
    }
    
    private func createCustomUserIndicator(color: UIColor, userLocation: CLLocation, uiView: GMSMapView, coordinator: Coordinator) {
        let marker = coordinator.customUserMarker ?? GMSMarker()
        if coordinator.customUserMarker == nil {
            coordinator.customUserMarker = marker
        }
        let markerImg = UIImage.imageWithColor(color: color,
                                               size: CGSize(width: 20.0, height: 20.0)) 
        
        marker.icon = markerImg
        marker.map = uiView
        marker.position = userLocation.coordinate
        marker.isTappable = false
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func getStartingPoint(coordinator: Coordinator) -> GMSCameraPosition {
        let coords: CLLocation = locationTracker.getLastKnownLocation() ?? .applePark
        let newCameraPosition = GMSCameraPosition.camera(withLatitude: coords.coordinate.latitude,
                                                         longitude: coords.coordinate.longitude,
                                                         zoom: 16)
        coordinator.latestUserLocation = .init(latitude: coords.coordinate.latitude,
                                               longitude: coords.coordinate.longitude)
        return newCameraPosition
    }
    
    private func setupStyling(for mapView: GMSMapView) {
        do {
            if let styleURL = Bundle.main.url(forResource: colorScheme == .light ? "style" : "darkStyle", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                Log.verbose("Unable to find style.json")
            }
        } catch {
            Log.verbose("One or more of the map styles failed to load. \(error)")
        }
    }
    
    func drawPolyline(_ uiView: GMSMapView, coordinator: Coordinator) {
        let newPath = GMSMutablePath()
        for point in path {
            newPath.add(.init(latitude: point.lat, longitude: point.long))
        }
        
        let polyline = coordinator.polyline
        polyline.path = newPath
        polyline.strokeColor = .accentColor
        polyline.strokeWidth = CGFloat(3)
        polyline.map = uiView
    }
    
    static func dismantleUIView(_ uiView: GMSMapView, coordinator: Coordinator) {
        coordinator.trackingToken?.stopTrackingUserPosition()
    }
}

fileprivate extension _MapView.MapType {
    var gmsMapviewType: GMSMapViewType {
        switch self {
        case .normal: return .normal
        case .hybrid: return .hybrid
        case .satellite: return .satellite
        case .terrain: return .terrain
        }
    }
}

fileprivate extension _MapView {
    class MapViewDelegateHandler: NSObject, GMSMapViewDelegate {
        let myLocationTapHandler: (GMSMapView) -> Bool
        let draggingHandler: (GMSMapView) -> Void
        let markerTapHandler: (GMSMapView, GMSMarker) -> Bool
        let idleAt: (GMSMapView, GMSCameraPosition) -> Void
        let didChangePosition: (GMSCameraPosition) -> Void
        
        init(myLocationTapHandler: @escaping (GMSMapView) -> Bool,
             draggingHandler: @escaping (GMSMapView) -> Void,
             markerTapHandler: @escaping (GMSMapView, GMSMarker) -> Bool,
             idleAt: @escaping (GMSMapView, GMSCameraPosition) -> Void,
             didChangePosition: @escaping (GMSCameraPosition) -> Void) {
            self.myLocationTapHandler = myLocationTapHandler
            self.draggingHandler = draggingHandler
            self.markerTapHandler = markerTapHandler
            self.idleAt = idleAt
            self.didChangePosition = didChangePosition
        }
        
        func didTapMyLocationButton(for mapView: GMSMapView) -> Bool {
            myLocationTapHandler(mapView)
        }
        
        func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
            guard gesture else { return }
            draggingHandler(mapView)
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            return markerTapHandler(mapView, marker)
        }
        
        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            idleAt(mapView, position)
            didChangePosition(position)
        }
    }
}
