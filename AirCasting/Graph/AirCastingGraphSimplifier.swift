// Created by Lunar on 03/11/2021.
//

import Foundation
import SwiftSimplify
import CoreLocation
import UIKit
import Charts

class AirCastingGraphSimplifier {
    // Maybe better name would be processPoints or sth --- think!
    func simplify<P: Point2DRepresentable>(points: [P], visibleElementsNumber: Int, thresholdLimit: Int) -> [P] {
        let fillFactor = Double((1 * Double(thresholdLimit) / Double((visibleElementsNumber) + 1)))
        var filled = 0.0
        var returnedPoints = [P]()
        var temporaryPoints = [P]()
        
        if fillFactor >= 1 {
            return points
        } else {
            for point in points {
                
                filled += fillFactor
                temporaryPoints.append(point)
                
                if filled > 1 {
                    filled = 0
                    
                    let sumOfPoints = Float(temporaryPoints.count)
                    
                    let XPoints = temporaryPoints.map( {$0.xValue} ).reduce(0, +)
                    let YPoints = temporaryPoints.map( {$0.yValue} ).reduce(0, +)
                    
                    returnedPoints.append(ChartDataEntry(x: Double(XPoints/sumOfPoints), y: Double(YPoints/sumOfPoints)) as! P)
                    temporaryPoints = []
                }
            }
            return returnedPoints
        }
    }
}
