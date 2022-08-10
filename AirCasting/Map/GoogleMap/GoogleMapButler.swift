// Created by Lunar on 27/07/2022.
//
import Foundation
import SwiftUI
import GoogleMaps
import Resolver

class GoogleMapButler: ObservableObject {
    @Binding var notes: [MapNote]
    
    private let coreMap: GoogleMapCore
    private let showMyLocationButton: Bool
    
    private var pathPoints: [PathPoint]
    private var isMyLocationEnabled: Bool
    private var mapPositioning: MapPositioning
    private var threshold: SensorThreshold?
    var notesNumber: Int { notes.count }
    
    init(pathPoints: [PathPoint],
         showMyLocationButton: Bool,
         isMyLocationEnabled: Bool = false,
         mapPositioning: MapPositioning = .init(),
         threshold: SensorThreshold? = nil,
         notes: Binding<[MapNote]>) {
        
        self.pathPoints = pathPoints
        self.showMyLocationButton = showMyLocationButton
        self.isMyLocationEnabled = isMyLocationEnabled
        self.threshold = threshold
        self.mapPositioning = mapPositioning
        self._notes = notes
        self.coreMap = GoogleMapCoreDefault()
    }
    
    var cameraUpdate: GMSCameraUpdate {
        let initialBounds = GMSCoordinateBounds()
        guard !pathPoints.isEmpty else {
            let location = coreMap.getLocationForEmptyPathPoints()
            return GMSCameraUpdate.setTarget(location)
        }
        
        guard mapPositioning.live else {
            let pathPointsBoundingBox = pathPoints.reduce(initialBounds) { bounds, point in
                bounds.includingCoordinate(point.location)
            }
            return GMSCameraUpdate.fit(pathPointsBoundingBox, withPadding: 1.0)
        }
        let pathPointsBoundingBox = initialBounds.includingCoordinate(pathPoints.last!.location)
        return GMSCameraUpdate.fit(pathPointsBoundingBox, withPadding: 1.0)
    }
    
    func initialMakeUIVIew(context: UIViewRepresentableContext<GoogleMapView>) -> GMSMapView {
        let mapView = coreMap.setStartingPointAndInitGMSMap()
        mapView.settings.myLocationButton = showMyLocationButton
        placeNotes(mapView, context: context)
        drawPolyline(mapView, context: context)
        mapView.isMyLocationEnabled = isMyLocationEnabled
        return mapView
    }
    
    func applyStylying(to mapView: GMSMapView) { coreMap.applyJSONStylying(to: mapView) }
    
    func defineMapType(_ uiView: GMSMapView) { coreMap.defineMapType(uiView) }
    
    func optionalTrackerLocation() -> (Double, Double) { coreMap.optionalTrackerLocation() }
    
    func placeNotes(_ uiView: GMSMapView, context: UIViewRepresentableContext<GoogleMapView>) {
        context.coordinator.noteMarkers.forEach { marker in
            marker.map = nil
        }
        context.coordinator.noteMarkers = []
        DispatchQueue.main.async {
            self.notes.forEach { note in
                let marker = GMSMarker()
                // 10 used here to be sure it will be on top of evertyhing
                marker.zIndex = 10
                let markerImage = note.markerImage
                let markerView = UIImageView(image: markerImage.withRenderingMode(.alwaysOriginal))
                marker.position = note.location
                marker.userData = note.id
                marker.iconView = markerView
                marker.map = uiView
                context.coordinator.noteMarkers.append(marker)
            }
        }
    }
    
    func drawPolyline(_ uiView: GMSMapView, context: UIViewRepresentableContext<GoogleMapView>) {
        let path = GMSMutablePath()
        let dot = context.coordinator.dot
        let polyline = context.coordinator.polyline
        
        for point in pathPoints {
            let coordinate = point.location
            path.add(coordinate)
            dot.position = coordinate
            dot.map = uiView
        }
        
        drawLastMeasurementPoint(dot)
        
        polyline.path = path
        polyline.strokeColor = .accentColor
        polyline.strokeWidth = CGFloat(Constants.Map.polylineWidth)
        polyline.map = uiView
    }
    
    func thresholdWitnessAssertion(context: UIViewRepresentableContext<GoogleMapView>) -> Bool {
        let thresholdWitness = ThresholdWitness(sensorThreshold: self.threshold)
        return thresholdWitness != context.coordinator.currentThresholdWitness
    }
    
    func thresholdWitnessUpdateOn(context: UIViewRepresentableContext<GoogleMapView>) {
        context.coordinator.currentThresholdWitness = ThresholdWitness(sensorThreshold: threshold)
    }
    
    func currentThresholdUpdateOn(context: UIViewRepresentableContext<GoogleMapView>) {
        context.coordinator.currentThreshold = threshold
    }
    
    fileprivate func drawLastMeasurementPoint(_ dot: GMSMarker) {
        guard mapPositioning.live || mapPositioning.fixed else {
            dot.map = nil
            return
        }
        
        guard let last = pathPoints.last else { return }
        
        let mainPoint = UIImage.imageWithColor(color: color(point: last), size: CGSize(width: Constants.Map.dotWidth, height: Constants.Map.dotHeight))
        dot.icon = mainPoint
    }
    
    func color(point: PathPoint) -> UIColor {
        guard let thresholds = threshold else { return .white }
        let formatter = Resolver.resolve(ThresholdFormatter.self, args: thresholds)
        let measurement = formatter.value(from: point.measurement)
        
        return Self.color(value: measurement, threshold: thresholds)
    }
    
    static func color(value: Int32, threshold: SensorThreshold?) -> UIColor {
        guard let threshold = threshold else { return .white }
        
        let veryLow = threshold.thresholdVeryLow
        let low = threshold.thresholdLow
        let medium = threshold.thresholdMedium
        let high = threshold.thresholdHigh
        let veryHigh = threshold.thresholdVeryHigh
        
        switch value {
        case veryLow ..< low:
            return UIColor.aircastingGreen
        case low ..< medium:
            return UIColor.aircastingYellow
        case medium ..< high:
            return UIColor.aircastingOrange
        case high ... veryHigh:
            return UIColor.aircastingRed
        default:
            return UIColor.aircastingGray
        }
    }
}
