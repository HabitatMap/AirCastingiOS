// Created by Lunar on 03/11/2021.
//

import Foundation
import SwiftSimplify
import Charts

final class AirCastingGraphSimplifier {
    
    static func simplify<P: Point2DRepresentable>(points: [P], visibleElementsNumber: Int, thresholdLimit: Int) -> [P] {
        let fillFactor = (1 * Double(thresholdLimit) / Double((visibleElementsNumber) + 1))
        var filled = 0.0
        var returnedPoints = [P]()
        var temporaryPoints = [P]()
        
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
    
    static func avaragePoints<P: Point2DRepresentable>(using temporaryPoints: [P]) -> P {
        
        let sumOfPoints = Float(temporaryPoints.count)
        
        let XPoints = temporaryPoints.map( {$0.xValue} ).reduce(0, +)
        let YPoints = temporaryPoints.map( {$0.yValue} ).reduce(0, +)
        
        return ChartDataEntry(x: Double(XPoints/sumOfPoints), y: Double(YPoints/sumOfPoints)) as! P
    }
}
