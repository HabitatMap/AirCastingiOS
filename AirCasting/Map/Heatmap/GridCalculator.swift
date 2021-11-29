// Created by Lunar on 29/11/2021.
//

import GoogleMaps
import Foundation

struct GridCalculator {
    let x: Int
    let y: Int
    let visibleRegion: VisibleRegionCoordinates
    let lonGridSize: Double
    let latGridSize: Double
    
    init(_ x: Int, _ y: Int, _ visibleRegion: VisibleRegionCoordinates, _ lonGridSize: Double, _ latGridSize: Double) {
        self.x = x
        self.y = y
        self.visibleRegion = visibleRegion
        self.lonGridSize = lonGridSize
        self.latGridSize = latGridSize
    }
    
    func southWestLatLng() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: southLatitude(), longitude: westLongitude())
    }
    
    func southEastLatLng() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: southLatitude(), longitude: eastLongitude())
    }
    
    func northEastLatLng() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: northLatitude(), longitude: eastLongitude())
    }
    
    func northWestLatLng() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: northLatitude(), longitude: westLongitude())
    }
    
    private func eastLongitude() -> Double {
        visibleRegion.lonWest + Double(x) * lonGridSize
    }
    
    private func westLongitude() -> Double {
        visibleRegion.lonWest + Double(x - 1) * lonGridSize
    }
    
    private func northLatitude() -> Double {
        visibleRegion.latSouth + Double(y) * latGridSize
    }
    
    private func southLatitude() -> Double {
        visibleRegion.latSouth + Double(y - 1) * latGridSize
    }
}
