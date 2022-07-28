// Created by Lunar on 03/11/2021.
//

import Foundation
import Charts

final class AirCastingGraphSimplifier {
    
    static func simplify(points: [ChartDataEntry], visibleElementsNumber: Int, thresholdLimit: Int) -> [ChartDataEntry] {
        let fillFactor = (1 * Double(thresholdLimit) / Double((visibleElementsNumber) + 1))
        var filled = 0.0
        var returnedPoints = [ChartDataEntry]()
        var temporaryPoints = [ChartDataEntry]()
        
        if fillFactor >= 1 {
            return points
        } else {
            points.forEach { point in
                filled += fillFactor
                temporaryPoints.append(point)
                
                if filled > 1 {
                    filled = 0
                    returnedPoints.append(avaragePoints(using: temporaryPoints))
                    temporaryPoints = []
                }
            }
            return returnedPoints
        }
    }
    
    static func avaragePoints(using temporaryPoints: [ChartDataEntry]) -> ChartDataEntry {
        
        let sumOfPoints = Double(temporaryPoints.count)
        
        let XPoints = temporaryPoints.map( {$0.x} ).reduce(0, +)
        let YPoints = temporaryPoints.map( {$0.y} ).reduce(0, +)
        
        return ChartDataEntry(x: round(Double(XPoints/sumOfPoints)), y: round(Double(YPoints/sumOfPoints)))
    }
}
