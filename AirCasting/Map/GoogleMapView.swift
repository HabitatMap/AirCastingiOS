//
//  GoogleMapView.swift
//  AirCasting
//
//  Created by Lunar on 26/01/2021.
//

import Foundation
import UIKit
import SwiftUI
import GoogleMaps
import GooglePlaces

struct GoogleMapView: UIViewRepresentable {
    typealias UIViewType = GMSMapView
    let pathPoints: [PathPoint]
    private(set) var thresholds: SensorThreshold?
    var isMyLocationEnabled: Bool
    private let delegateRelay = GoogleMapViewDelegate()
    private var onPositionChange: (([PathPoint]) -> ())? = nil
    
    init(pathPoints: [PathPoint], thresholds: SensorThreshold? = nil, isMyLocationEnabled: Bool = false) {
        self.pathPoints = pathPoints
        self.thresholds = thresholds
        self.isMyLocationEnabled = isMyLocationEnabled
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        GMSServices.provideAPIKey(GOOGLE_MAP_KEY)
        GMSPlacesClient.provideAPIKey(GOOGLE_MAP_KEY)
        
        let startingPoint = setStartingPoint(points: pathPoints)
        
        let frame = CGRect(x: 0, y: 0,
                           width: 300,
                           height: 300)
        let mapView = GMSMapView.map(withFrame: frame,
                                     camera: startingPoint)
        
        mapView.delegate = delegateRelay
        delegateRelay.onPosistionChange = positionChanged
        
        mapView.isMyLocationEnabled = isMyLocationEnabled
        
        context.coordinator.myLocationSink = mapView.publisher(for: \.myLocation)
            .sink { [weak mapView] (location) in
                guard let coordinate = location?.coordinate else { return }
                mapView?.animate(toLocation: coordinate)
            }
        return mapView
    }
    
    /// Adds an action for when the map viewport is changed.
    /// - Parameter action: an action block that takes an array of currently visible `PathPoint`s.
    func onPositionChange(action: @escaping (_ visiblePoints: [PathPoint]) -> ()) -> Self {
        var newSelf = self
        newSelf.onPositionChange = action
        return newSelf
    }
    
    private func positionChanged(for mapView: GMSMapView) {
        let visibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: visibleRegion)
        let visiblePathPoints = pathPoints.filter { bounds.contains($0.location) }
        onPositionChange?(visiblePathPoints)
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        
        // Drawing the path
        let path = GMSMutablePath()
        for point in pathPoints {
            let coordinate = point.location
            path.add(coordinate)
        }
        let polyline = GMSPolyline(path: path)
        
        let spans = pathPoints.map { point -> GMSStyleSpan in
            let color = colorPolyline(point: point)
            return GMSStyleSpan(style: GMSStrokeStyle.solidColor(color),
                                segments: 1)
        }
        
        // Update starting point
        if !context.coordinator.didSetInitLocation && !pathPoints.isEmpty {
            let updatedCameraPosition = setStartingPoint(points: pathPoints)
            DispatchQueue.main.async {
                uiView.camera = updatedCameraPosition
            }
            context.coordinator.didSetInitLocation = true
        }
        polyline.spans = spans
        polyline.strokeWidth = 6
        polyline.map = uiView
    }
    
    func setStartingPoint(points: [PathPoint]) -> GMSCameraPosition {
        if let lastPoint = points.last {
            let long = lastPoint.location.longitude
            let lat = lastPoint.location.latitude
            let newCameraPosition =  GMSCameraPosition.camera(withLatitude: lat,
                                                              longitude: long,
                                                              zoom: 17)
            return newCameraPosition
        } else {
            let appleParkPosition = GMSCameraPosition.camera(withLatitude: 37.35,
                                                            longitude: -122.05,
                                                            zoom: 17)
            return appleParkPosition
        }
    }

    func colorPolyline(point: PathPoint) -> UIColor {
        let measurement = Int32(point.measurement)
        guard let thresholds = thresholds else { return .white }
        
        let veryLow = thresholds.thresholdVeryLow
        let low = thresholds.thresholdLow
        let medium = thresholds.thresholdMedium
        let high = thresholds.thresholdHigh
        let veryHigh = thresholds.thresholdVeryHigh
        
        switch measurement {
        case veryLow ..< low:
            return UIColor.aircastingGreen
        case low ..< medium:
            return UIColor.aircastingYellow
        case medium ..< high:
            return UIColor.aircastingOrange
        case high ... veryHigh:
            return UIColor.aircastingRed
        default:
            return UIColor.white
        }
    }
    
    class Coordinator {
        var didSetInitLocation: Bool = false   
        var myLocationSink: Any?
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    @objc
    /// A relay for google map delegate which requires an `NSObjectProtocol` conformance.
    private class GoogleMapViewDelegate: NSObject, GMSMapViewDelegate {
        var onPosistionChange: ((GMSMapView) -> ())?
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            onPosistionChange?(mapView)
        }
    }
}

#if DEBUG
struct GoogleMapView_Previews: PreviewProvider {
    static var previews: some View {
        GoogleMapView(pathPoints: [PathPoint(location: CLLocationCoordinate2D(latitude: 40.73,
                                                                              longitude: -73.93),
                                             measurementTime: .distantPast,
                                             measurement: 30),
                                   PathPoint(location: CLLocationCoordinate2D(latitude: 40.83,
                                                                              longitude: -73.93),
                                             measurementTime: .distantPast,
                                             measurement: 30),
                                   PathPoint(location: CLLocationCoordinate2D(latitude: 40.93,
                                                                              longitude: -73.83),
                                             measurementTime: .distantPast,
                                             measurement: 30)],
                      thresholds: SensorThreshold.mock)
            .padding()
    }
}
#endif
