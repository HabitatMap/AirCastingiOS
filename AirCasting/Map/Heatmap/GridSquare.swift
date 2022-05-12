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
    @InjectedObject private var userSettings: UserSettings
    private var selectedStream: MeasurementStreamEntity?
    
    private var adjustedAverage: Int32? {
        guard let averagedValue = averagedValue, let selectedStream = selectedStream else { return nil }

        return selectedStream.isTemperature && userSettings.convertToCelsius ? Int32(TemperatureConverter.calculateFahrenheit(celsius: averagedValue)) : Int32(averagedValue)
    }
    
    init(mapView: GMSMapView, sensorThreshold: SensorThreshold, selectedStream: MeasurementStreamEntity?, _ southWestLatLng: CLLocationCoordinate2D, _ southEastLatLng: CLLocationCoordinate2D, _ northEastLatLng: CLLocationCoordinate2D, _ northWestLatLng: CLLocationCoordinate2D) {
        self.mapView = mapView
        self.sensorThreshold = sensorThreshold
        self.selectedStream = selectedStream
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
    
    func inBounds(coordinates: CLLocationCoordinate2D?) -> Bool {
        let bounds = GMSCoordinateBounds(coordinate: southWestLatLng, coordinate: northEastLatLng)
        
        return coordinates != nil ? bounds.contains(coordinates!) : false
    }
    
    mutating func addMeasurement(_ pathPoint: PathPoint) {
        sum += pathPoint.measurement
        number += 1
        calculateAverage()
        
        guard let adjustedAverage = adjustedAverage else { return }
        let color: UIColor = GoogleMapView.color(value: adjustedAverage, threshold: sensorThreshold).withAlphaComponent(0.5)
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
            polygon?.map = nil
        }
        
        polygon?.map = mapView
        newColor = false
    }
    
    func shouldDrawPolygon() -> Bool {
        return self.newColor || (polygon?.map == nil && averagedValue != nil)
    }
    
    
    mutating func calculateAverage() {
        self.averagedValue = sum / Double(number)
    }
    
    func remove() {
        polygon?.map = nil
    }
}
