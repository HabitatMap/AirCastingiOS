// Created by Lunar on 09/09/2022.
//

import UIKit
import SwiftUI
import GoogleMaps
import Combine

extension _MapView {
    class Coordinator {
        var latestUserLocation: CLLocation?
        var polyline = GMSPolyline()
        var customUserMarker: GMSMarker?
        var myLocationSink: Any?
        var mapViewDelegateHandler: MapViewDelegateHandler?
        var suspendTracking: Bool = false
        var gmsMarkers: [GMSMarker] = []
        var previousFrameMarkers: [Marker] = []
    }
}

protocol UserTracker {
    func startTrackingUserPosision(_ newPos: @escaping (CLLocation) -> Void)
}

class DummyTracker: UserTracker {
    func startTrackingUserPosision(_ newPos: @escaping (CLLocation) -> Void) {
        newPos(self.location)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            newPos(self.location)
        }
    }
    
    var location: CLLocation = .init(latitude: CLLocation.krakow.coordinate.latitude, longitude: CLLocation.krakow.coordinate.longitude)
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
        case custom(color: Color) // AC color dot
    }
    
    struct PathPoint {
        let lat: Double
        let long: Double
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
            lhs.id == rhs.id &&
            lhs.location == rhs.location
        }
    }
}

struct _MapView: UIViewRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    
    private let path: [PathPoint]
    private let type: MapType
    private let trackingStyle: TrackingStyle
    private let userIndicatorStyle: UserIndicatorStyle
    private let userTracker: UserTracker
    private let markers: [Marker]
    
    init(path: [PathPoint], type: MapType, trackingStyle: TrackingStyle, userIndicatorStyle: UserIndicatorStyle, userTracker: UserTracker, markers: [Marker]) {
        self.path = path
        self.type = type
        self.trackingStyle = trackingStyle
        self.userIndicatorStyle = userIndicatorStyle
        self.userTracker = userTracker
        self.markers = markers
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        let startingPoint = getStartingPoint(context: context)
        let mapView = GMSMapView(frame: .zero, camera: startingPoint)
        setupMyLocationButtonVisibility(for: mapView)
        mapView.mapType = type.gmsMapviewType
        
        setupMapDelegate(in: mapView, context: context)
        
        if isUserPositionTrackingRequired {
            userTracker.startTrackingUserPosision { [weak coord = context.coordinator] in
                coord?.latestUserLocation = $0
            }
        }
        
        // setupStyling(for: mapView)
        do {
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                let s = try GMSMapStyle(contentsOfFileURL: styleURL)
                mapView.mapStyle = s
            } else {
                print("Unable to find style.json")
            }
        } catch {
            print("One or more of the map styles failed to load. \(error)")
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        setupUserIndicatorStyle(with: userIndicatorStyle, in: uiView, with: context)
        if markers != context.coordinator.previousFrameMarkers {
            placeMarkers(uiView, markers: markers, context: context)
        }
        context.coordinator.previousFrameMarkers = markers
        drawPolyline(uiView, context: context)
//        setupStyling(for: uiView)
        
        guard !context.coordinator.suspendTracking else { return }
        updateCameraPosition(in: uiView, context: context)
    }
    
    private func setupMyLocationButtonVisibility(for mapView: GMSMapView) {
        guard case (.none, .none) = (trackingStyle, userIndicatorStyle) else {
            mapView.settings.myLocationButton = true; return
        }
        mapView.settings.myLocationButton = false
    }
    
    private func setupMapDelegate(in mapView: GMSMapView, context: Context) {
        context.coordinator.mapViewDelegateHandler = MapViewDelegateHandler(myLocationTapHandler: {
            handleLocationButtonTapped(in: $0, context: context)
            return true
        }, draggingHandler: { _ in
            context.coordinator.suspendTracking = true
        }, markerTapHandler: { mapView, marker in
            let marker = context.coordinator.previousFrameMarkers.first(where: { $0.id == (marker.userData as? Int) })
            marker?.handler?()
            return marker?.handler != nil
        })
        
        mapView.delegate = context.coordinator.mapViewDelegateHandler
    }
    
    private func placeMarkers(_ uiView: GMSMapView, markers: [Marker], context: Context) {
        clearMarkers(in: context)
        DispatchQueue.main.async {
            context.coordinator.gmsMarkers = markers.map { createMarker(from: $0, in: uiView, with: context) }
        }
    }
    
    private func clearMarkers(in context: Context) {
        context.coordinator.gmsMarkers.forEach { marker in
            marker.map = nil
        }
        context.coordinator.gmsMarkers = []
    }
    
    private func createMarker(from marker: Marker, in uiView: GMSMapView, with context: Context) -> GMSMarker {
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
    
    private func updateCameraPosition(in view: GMSMapView, context: Context) {
        switch trackingStyle {
        case .latestPathPoint:
            centerMapOnLatestPathPoint(in: view, context: context)
        case .none:
            break
        case .wholePath:
            centerMapOnWholePath(in: view, context: context)
        case .user:
            centerMapOnUserPosition(in: view, context: context)
        }
    }
    
    private func handleLocationButtonTapped(in view: GMSMapView, context: Context) {
        context.coordinator.suspendTracking = false
        switch trackingStyle {
        case .none:
            centerMapOnUserPosition(in: view, context: context)
        case .user:
            centerMapOnUserPosition(in: view, context: context)
        case .latestPathPoint:
            centerMapOnLatestPathPoint(in: view, context: context)
        case .wholePath:
            centerMapOnWholePath(in: view, context: context)
        }
    }
    
    private func centerMapOnUserPosition(in view: GMSMapView, context: Context) {
        guard let latestUserLocation = context.coordinator.latestUserLocation else { return }
        let userPos = GMSCameraPosition(target: latestUserLocation.coordinate, zoom: 16.0) // TODO: Configure later
        view.animate(to: userPos)
    }
    
    private func centerMapOnLatestPathPoint(in view: GMSMapView, context: Context) {
        guard let lastPathPoint = path.last else { return }
        let userPos = GMSCameraPosition(target: .init(latitude: lastPathPoint.lat, longitude: lastPathPoint.long), zoom: 16.0) // TODO: Configure later
        view.animate(to: userPos)
    }
    
    private func centerMapOnWholePath(in view: GMSMapView, context: Context) {
        let initialBounds = GMSCoordinateBounds()
        let pathPointsBoundingBox = path.reduce(initialBounds) { bounds, point in
            bounds.includingCoordinate(.init(latitude: point.lat, longitude: point.long))
        }
        let cameraUpdate = GMSCameraUpdate.fit(pathPointsBoundingBox, withPadding: 1.0)
        view.moveCamera(cameraUpdate)
    }
    
    private var isUserPositionTrackingRequired: Bool {
        switch (trackingStyle, userIndicatorStyle) {
        case (.user, _): return true
        case (_, .custom): return true
        // NOTE: for (_, .standard) case we don't need to track the user because GMSMapView can take care of that for us
        default: return false
        }
    }
    
    private func setupUserIndicatorStyle(with style: UserIndicatorStyle, in view: GMSMapView, with context: Context) {
        guard let userLocation = context.coordinator.latestUserLocation else { return }
        switch style {
        case .none:
            break
        case .standard:
            view.isMyLocationEnabled = true
        case .custom(let color):
            createCustomUserIndicator(color: color, userLocation: userLocation, uiView: view, context: context)
        }
    }
    
    private func createCustomUserIndicator(color: Color, userLocation: CLLocation, uiView: GMSMapView, context: Context) {
        let marker = context.coordinator.customUserMarker ?? GMSMarker()
        if context.coordinator.customUserMarker == nil {
            context.coordinator.customUserMarker = marker
        }
        let markerImg = UIImage.imageWithColor(color: UIColor(color),
                                               size: CGSize(width: 20.0, height: 20.0)) // Customize with styling later?
        
        marker.icon = markerImg
        marker.map = uiView
        marker.position = userLocation.coordinate
        marker.isTappable = false
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func getStartingPoint(context: Context) -> GMSCameraPosition {
        let coords: CLLocation = context.coordinator.latestUserLocation ?? .krakow //TODO: Swtich to apple park
        let newCameraPosition = GMSCameraPosition.camera(withLatitude: coords.coordinate.latitude,
                                                         longitude: coords.coordinate.longitude,
                                                         zoom: 16)
        return newCameraPosition
    }
    
    private func setupStyling(for mapView: GMSMapView) {
        print("Setting styling for colorscheme: \(colorScheme)")
        do {
            if let styleURL = Bundle.main.url(forResource: colorScheme == .light ? "style" : "darkStyle", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                print("Unable to find style.json")
            }
        } catch {
            print("One or more of the map styles failed to load. \(error)")
        }
    }
    
    func drawPolyline(_ uiView: GMSMapView, context: Context) {
        let newPath = GMSMutablePath()
        for point in path {
            newPath.add(.init(latitude: point.lat, longitude: point.long))
        }
        
        let polyline = context.coordinator.polyline
        polyline.path = newPath
        polyline.strokeColor = .blue //TODO: Change it (styling)
        polyline.strokeWidth = CGFloat(3)
        polyline.map = uiView
    }
    
    private func followUser(in mapView: GMSMapView, context: Context) {
        mapView.isMyLocationEnabled = true
        // TODO: Check on device if we can use the `LocationTracker` instead
        context.coordinator.myLocationSink = mapView.publisher(for: \.myLocation)
            .sink { [weak mapView] (location) in
                guard let coordinate = location?.coordinate else { return }
                mapView?.animate(toLocation: coordinate)
            }
    }
}

extension _MapView.MapType {
    var gmsMapviewType: GMSMapViewType {
        switch self {
        case .normal: return .normal
        case .hybrid: return .hybrid
        case .satellite: return .satellite
        case .terrain: return .terrain
        }
    }
}

extension UIImage {
    class func imageWithColor(color: UIColor, size: CGSize = CGSize(width: 10, height: 10)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            let roundedImage = image.withRoundedCorners(radius: 12)
            UIGraphicsEndImageContext()
            return roundedImage!
        } else {
            return UIImage()
        }
    }
    
    public func withRoundedCorners(radius: CGFloat? = nil) -> UIImage? {
        let maxRadius = min(size.width, size.height) / 2
        let cornerRadius: CGFloat
        if let radius = radius, radius > 0 && radius <= maxRadius {
            cornerRadius = radius
        } else {
            cornerRadius = maxRadius
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

//@objc
//class CLLocationUserTracker: NSObject, UserTracker, CLLocationManagerDelegate {
//    private var callback: ((CLLocation) -> Void)? {
//        didSet {
//            guard let latestLoc else { return }
//            callback?(latestLoc)
//        }
//    }
//    
//    private var latestLoc: CLLocation? {
//        didSet {
//            guard let latestLoc else { return }
//            callback?(latestLoc)
//        }
//    }
//    
//    let manager: CLLocationManager = {
//        let manager = CLLocationManager()
//        manager.desiredAccuracy = kCLLocationAccuracyBest
//        manager.pausesLocationUpdatesAutomatically = false
//        manager.startUpdatingLocation()
//        return manager
//    }()
//    
//    override init() {
//        super.init()
//        self.manager.delegate = self
//        print("Requesting authorization")
//        self.manager.requestAlwaysAuthorization()
//    }
//    
//    func startTrackingUserPosision(_ newPos: @escaping (CLLocation) -> Void) {
//        print("Callback set")
//        callback = newPos
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let loc = locations.first else { return }
//        print("new location: \(loc)")
//        latestLoc = loc
//    }
//}

extension _MapView {
    class MapViewDelegateHandler: NSObject, GMSMapViewDelegate {
        let myLocationTapHandler: (GMSMapView) -> Bool
        let draggingHandler: (GMSMapView) -> Void
        let markerTapHandler: (GMSMapView, GMSMarker) -> Bool
        
        init(myLocationTapHandler: @escaping (GMSMapView) -> Bool,
             draggingHandler: @escaping (GMSMapView) -> Void,
             markerTapHandler: @escaping (GMSMapView, GMSMarker) -> Bool) {
            self.myLocationTapHandler = myLocationTapHandler
            self.draggingHandler = draggingHandler
            self.markerTapHandler = markerTapHandler
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
    }
}
