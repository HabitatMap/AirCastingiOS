// Created by Lunar on 18/06/2021.
//

import SwiftUI
import Charts

class TimeAxisRenderer: XAxisRenderer {
    
    lazy var dateFormatter = DateFormatters.TimeAxisRenderer.shortUTCDateFormatter
    
    override func drawLabels(context: CGContext, pos: CGFloat, anchor: CGPoint) {
        let minPxX = viewPortHandler.contentLeft
        let maxPxX = viewPortHandler.contentRight
        let bottomPxY = viewPortHandler.contentBottom + 5
        
        let minX = transformer!.valueForTouchPoint(.init(x: minPxX, y: 0)).x
        let maxX = transformer!.valueForTouchPoint(.init(x: maxPxX, y: 0)).x
        let startingTime = DateBuilder.getDateWithTimeIntervalSince1970(TimeInterval(minX))
        let timeLeftLabel = dateFormatter.string(from: startingTime)
        
        drawLabel(context: context,
                  formattedLabel: timeLeftLabel,
                  x: minPxX + 10,
                  y: bottomPxY,
                  attributes: [.foregroundColor : UIColor.aircastingGray,
                               .font: Fonts.muliHeadingUIFont1],
                  constrainedToSize: .zero,
                  anchor: .zero,
                  angleRadians: 0)
        
        let endTime = DateBuilder.getDateWithTimeIntervalSince1970(TimeInterval(maxX))
        let timeRightLabel = dateFormatter.string(from: endTime)
        
        drawLabel(context: context,
                  formattedLabel: timeRightLabel,
                  x: maxPxX - 50,
                  y: bottomPxY,
                  attributes: [.foregroundColor : UIColor.aircastingGray,
                               .font: Fonts.muliHeadingUIFont1],
                  constrainedToSize: .zero,
                  anchor: .zero,
                  angleRadians: 0)
    }
}

class MultiColorGridRenderer: YAxisRenderer {
    
    var thresholds: [Float] = []
    
    var colors = [UIColor.graphGreen,
                  UIColor.graphYellow,
                  UIColor.graphOrange,
                  UIColor.graphRed]
    
    override func renderGridLines(context: CGContext) {
        let colorThresholds = Array(thresholds.dropFirst())
        let thresholdVeryHigh = CGFloat(thresholds.last ?? 200)
        let thresholdVeryLow = CGFloat(thresholds[0])
        for index in colorThresholds.indices.reversed() {
            let thresholdValue = CGFloat(colorThresholds[index])
            let yMax = gridClippingRect.maxY
            guard thresholdVeryHigh > thresholdVeryLow else {
                Log.error("Threshold very high was lower than threshold very low")
                return
            }
            let height = (thresholdValue - thresholdVeryLow) * yMax / (thresholdVeryHigh - thresholdVeryLow)
            let y = yMax - height
            
            context.setFillColor(colors[index].cgColor)
            context.fill((CGRect(x: gridClippingRect.minX,
                                 y: y,
                                 width: gridClippingRect.width,
                                 height: CGFloat(height))))
        }
    }
}
