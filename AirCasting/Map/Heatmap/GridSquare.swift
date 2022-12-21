// Created by Lunar on 29/11/2021.
//

import GoogleMaps
import Foundation
import Resolver

struct GridSquare {
    private var mapView: GMSMapView! = nil
    private var sum: Double = 0.0
    private var number: Int = 0
    private var averagedValue: Double? = nil
    private var fillColor: UIColor? = nil
    private var sensorThreshold: SensorThreshold! = nil
    
    private var polygon: GMSPolygon? = nil
    private var newColor: Bool = false
    
    private var southWestLatLng: CLLocationCoordinate2D
    private var southEastLatLng: CLLocationCoordinate2D
    var northEastLatLng: CLLocationCoordinate2D
    private var northWestLatLng: CLLocationCoordinate2D
    
    init(mapView: GMSMapView, sensorThreshold: SensorThreshold, _ southWestLatLng: CLLocationCoordinate2D, _ southEastLatLng: CLLocationCoordinate2D, _ northEastLatLng: CLLocationCoordinate2D, _ northWestLatLng: CLLocationCoordinate2D) {
        self.mapView = mapView
        self.sensorThreshold = sensorThreshold
        self.southWestLatLng = southWestLatLng
        self.southEastLatLng = southEastLatLng
        self.northEastLatLng = northEastLatLng
        self.northWestLatLng = northWestLatLng
        
        let rect = GMSMutablePath()
        rect.add(southWestLatLng)
        rect.add(southEastLatLng)
        rect.add(northEastLatLng)
        rect.add(northWestLatLng)
        self.polygon = GMSPolygon(path: rect)
    }
    
    mutating func addMeasurement(_ pathPoint: HeatMapPoint) {
        sum += pathPoint.measurement
        number += 1
        calculateAverage()
        
        guard let averagedValue = averagedValue else { return }
        let formatter = Resolver.resolve(ThresholdFormatter.self, args: sensorThreshold)
        let color = _MapViewThresholdFormatter
                        .shared
                        .getProperColor(value: formatter.value(from: averagedValue),
                                        threshold: sensorThreshold)
            .withAlphaComponent(0.5)
        if color != fillColor {
            fillColor = color
            newColor = true
            polygon?.fillColor = color
        }
    }
    
    mutating func drawPolygon() {
        if (shouldDrawPolygon()) {
            addPolygon()
        }
    }
    
    mutating func addPolygon() {
        if (polygon?.map != nil) {
            remove()
        }
        
        polygon?.map = mapView
        newColor = false
    }
    
    mutating func calculateAverage() {
        self.averagedValue = sum / Double(number)
    }
    
    func shouldDrawPolygon() -> Bool {
        return self.newColor || (polygon?.map == nil && averagedValue != nil)
    }
    
    func inBounds(coordinates: CLLocationCoordinate2D?) -> Bool {
        let bounds = GMSCoordinateBounds(coordinate: southWestLatLng, coordinate: northEastLatLng)
        guard let coordinates else { return false }
        return bounds.contains(coordinates)
    }
    
    func remove() {
        polygon?.map = nil
    }
}
