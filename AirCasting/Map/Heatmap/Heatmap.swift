// Created by Lunar on 10/11/2021.
//

import GoogleMaps
import Foundation

/*
 * This is a custom "heatmap" for the Aircasting maps. The way it works is similar to what we already have
 * on the website when you switch on "Crowdmap" but it works for single session and for mobile active measurements.
 * We redraw the heatmap with every zoom and pan, because the grid squares are always calculated on the visible part of the map.
 * We divide the visible are of the map into virtual squares (gridSquares). We calculate the size of the single square
 * using heatmap density and size of the visible area on the screen.
 * For example, a "portrait" map may be divided into 10x12 grid. In this case gridSizeX = 10 and gridSizeY = 12.
 * For each grid square we calculate coordinates for each corner so we can use them to draw a Polygon if needed.
 *
 * NW-----NE
 * |      |
 * |      |
 * SW-----SE
 *
 * On heatmap redraw, we go through all measurements we want to map and assign them to squares. The algorithm for this
 * is a simple binary search based on grid squares coordinates. On assigning measurements, we caclulate the average
 * value of each square and assign an appropriate level.
 *
 * With every new measurement, the average of appropriate square is recalculated and polygon redrawn
 * (only if the level has changed)
 */

struct Heatmap {
    private let density: Int = 10
    
    var mapView: GMSMapView
    var gridSquares = [String: GridSquare]()
    var visibleRegion: VisibleRegionCoordinates! = nil
    var sensorThreshold: SensorThreshold! = nil
    
    var gridSizeX: Int
    var gridSizeY: Int
    
    init(_ uiView: GMSMapView, sensorThreshold: SensorThreshold, mapWidth: Int, mapHeight: Int) {
        self.mapView = uiView
        self.sensorThreshold = sensorThreshold
        
        let size = min(mapWidth, mapHeight) / density
        
        self.gridSizeX = mapWidth / size
        self.gridSizeY = mapHeight / size
        
        self.visibleRegion = getVisibleRegionCoordinates(mapView: uiView)
        
        initGrid()
    }
    
    mutating func drawHeatMap(pathPoints: [HeatMapPoint]) {
        for pathPoint in pathPoints {
            assignMeasurementToSquare(pathPoint)
        }
        drawPolygons()
    }
    
    
    func drawPolygons() {
        for x in 1...gridSizeX {
            for y in 1...gridSizeY {
                var gridSquare = getGridSquare(x: x, y: y)
                gridSquare?.drawPolygon()
            }
        }
    }
    
    mutating func remove() {
        for x in 1...gridSizeX {
            for y in 1...gridSizeY {
                removeGridSquare(x: x, y: y)
            }
        }
    }
    
    mutating func removeGridSquare(x: Int, y: Int) {
        getGridSquare(x: x, y: y)?.remove()
        setGridSquare(x, y, nil)
    }
    
    private mutating func assignMeasurementToSquare(_ pathPoint: HeatMapPoint) {
        guard let squareXY = getSquareXY(pathPoint, indexXstart: 0, indexXend: gridSizeX - 1, indexYstart: 0, indexYend: gridSizeY - 1) else { return }
        var gridSquare = getGridSquare(x: squareXY.0, y: squareXY.1)
        gridSquare?.addMeasurement(pathPoint)
        setGridSquare(x: squareXY.0, y: squareXY.1, gridSquare: gridSquare)
    }
    
    private func getSquareXY(_ pathPoint: HeatMapPoint, indexXstart: Int, indexXend: Int, indexYstart: Int, indexYend: Int) -> (Int, Int)? {
        let middleX = indexXstart  + (indexXend - indexXstart) / 2
        let middleY = indexYstart  + (indexYend - indexYstart) / 2
        let middleSquare = getGridSquare(x: middleX + 1, y: middleY + 1)
        
        guard middleSquare != nil else { return nil }
        
        // We check every time if point is in binds of middle square. It may be the last square checked (indexStart == indexEnd)
        if let middleSquare = middleSquare {
            if (middleSquare.inBounds(coordinates: pathPoint.location)) {
                return (middleX + 1, middleY + 1)
            }
        }
        // if this is the last square checked and point is not in its bounds, return nil
        if (indexXstart == indexXend && indexYstart == indexYend) {
            return nil
        }
        
        var newIndexXstart = indexXstart
        var newIndexYstart = indexYstart
        var newIndexXend = indexXend
        var newIndexYend = indexYend
        
        let middleLon = middleSquare?.northEastLatLng.longitude
        let middleLat = middleSquare?.northEastLatLng.latitude
        
        guard middleLon != nil, middleLat != nil else {
            return nil
        }
        
        if let middleLon = middleLon {
            let longitude = pathPoint.location.longitude
            if (longitude >= middleLon) {
                newIndexXstart = middleX + 1
            } else {
                newIndexXend = middleX
            }
        }
        
        if let middleLat = middleLat {
            let latitude = pathPoint.location.latitude
            if (latitude >= middleLat) {
                newIndexYstart = middleY + 1
            } else {
                newIndexYend = middleY
            }
        }
        return getSquareXY(pathPoint, indexXstart: newIndexXstart, indexXend: newIndexXend, indexYstart: newIndexYstart, indexYend: newIndexYend)
    }
    
    private func getGridSquare(x: Int, y: Int) -> GridSquare? {
        return gridSquares[gridSquareKey(x, y)]
    }
    
    private mutating func setGridSquare(x: Int, y: Int, gridSquare: GridSquare?) {
        gridSquares[gridSquareKey(x, y)] = gridSquare
    }
    
    private func getVisibleRegionCoordinates(mapView: GMSMapView) -> VisibleRegionCoordinates {
        let visibleRegion = mapView.projection.visibleRegion()
        
        return VisibleRegionCoordinates(
            visibleRegion.farLeft.latitude,
            visibleRegion.nearLeft.latitude,
            visibleRegion.farRight.longitude,
            visibleRegion.nearLeft.longitude
        )
    }
    
    private mutating func initGrid() {
        
        let lonGridSize = (visibleRegion.lonEast - visibleRegion.lonWest) / Double(gridSizeX)
        let latGridSize = (visibleRegion.latNorth - visibleRegion.latSouth) / Double(gridSizeY)
        
        for x in 1...gridSizeX {
            for y in 1...gridSizeY {
                let gridCalculator = GridCalculator(x, y, visibleRegion, lonGridSize, latGridSize)
                
                setGridSquare(x, y, GridSquare(
                    mapView: mapView,
                    sensorThreshold: sensorThreshold,
                    gridCalculator.southWestLatLng(),
                    gridCalculator.southEastLatLng(),
                    gridCalculator.northEastLatLng(),
                    gridCalculator.northWestLatLng()
                ))
            }
        }
    }
    
    private mutating func setGridSquare(_ x: Int, _ y: Int, _ gridSquare: GridSquare?) {
        self.gridSquares[gridSquareKey(x, y)] = gridSquare
    }
    
    private func gridSquareKey(_ x: Int, _ y: Int) -> String {
        "\(x)_\(y)"
    }
}
