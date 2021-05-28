//
//  PollutionGraph.swift
//  AirCasting
//
//  Created by Monika Śmiałko on 15/01/2021.
//

import SwiftUI
import Charts

class AirCastingGraph: UIView {
    
    let lineChartView = LineChartView()
    var renderer: MultiColorGridRenderer?
    var didMoveOrScaleGraph = false
    
    init() {
        super.init(frame: .zero)
        self.addSubview(lineChartView)
        lineChartView.delegate = self
        try? setupGraph()
    }
    
    private func setupGraph() throws {
        
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lineChartView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            lineChartView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            lineChartView.topAnchor.constraint(equalTo: self.topAnchor),
            lineChartView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        //set edges
        lineChartView.minOffset = 0.0
        
        //remove border lines and legend
        lineChartView.xAxis.drawLabelsEnabled = false
        
        lineChartView.leftAxis.drawLabelsEnabled = false
        lineChartView.leftAxis.drawAxisLineEnabled = false
        lineChartView.leftAxis.drawGridLinesEnabled = true
        
        lineChartView.rightAxis.enabled = false
        lineChartView.rightAxis.drawLabelsEnabled = false
        lineChartView.rightAxis.drawAxisLineEnabled = false
        
        lineChartView.legend.enabled = false
        lineChartView.scaleYEnabled = false
        
        lineChartView.xAxis.drawLabelsEnabled = true
        lineChartView.xAxis.labelCount = 2
        lineChartView.extraBottomOffset = 25
                
        lineChartView.xAxisRenderer = TimeAxisRenderer(viewPortHandler: lineChartView.viewPortHandler,
                                                       xAxis: lineChartView.xAxis,
                                                       transformer: lineChartView.getTransformer(forAxis: .left))
        
        
        renderer = MultiColorGridRenderer(viewPortHandler: lineChartView.viewPortHandler,
                                          yAxis: lineChartView.leftAxis,
                                          transformer: lineChartView.getTransformer(forAxis: .left))
        guard let renderer = renderer else {
            throw GraphError.rendererError
        }
        lineChartView.leftYAxisRenderer = renderer
    }
    
    private func zoomoutToThirtyMinutes(dataSet: LineChartDataSet) {
        let thirtyMinutesMeasurementCount = 60 * 30
        lineChartView.setVisibleXRangeMaximum(Double(thirtyMinutesMeasurementCount))
        lineChartView.moveViewToX(dataSet.xMax)
        //enable zoom out
        lineChartView.setVisibleXRangeMaximum(dataSet.xMax)
    }
    
    func updateWithThreshold(thresholdValues: [Float]) throws {
        guard let renderer = renderer else {
            throw GraphError.rendererError
        }
        renderer.thresholds = thresholdValues
        
        lineChartView.leftAxis.axisMinimum = Double(thresholdValues.first ?? 0)
        lineChartView.leftAxis.axisMaximum = Double(thresholdValues.last ?? 200)
        
        lineChartView.data = lineChartView.data
        lineChartView.setNeedsDisplay()
    }
    
    func updateWithEntries(entries: [ChartDataEntry], isAutozoomEnabled: Bool) {
        let dataSet = LineChartDataSet(entries: entries)
        let data = LineChartData(dataSet: dataSet)
        lineChartView.data = data
        
        //format data labels
        data.setDrawValues(false)
        
        // Line styling
        dataSet.drawCirclesEnabled = false
        dataSet.setColor(UIColor(.white))
        dataSet.mode = .linear
        dataSet.lineWidth = 4
        
        if !didMoveOrScaleGraph && isAutozoomEnabled {
            zoomoutToThirtyMinutes(dataSet: dataSet)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AirCastingGraph: ChartViewDelegate {
    
    // Callbacks when the chart is scaled / zoomed via pinch zoom gesture.
    @objc func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        didMoveOrScaleGraph = true
    }
    // Callbacks when the chart is moved / translated via drag gesture.
    @objc func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        didMoveOrScaleGraph = true
    }
}

class TimeAxisRenderer: XAxisRenderer {
    
    lazy var dateFormatter = DateFormatter()
    
    override func drawLabels(context: CGContext, pos: CGFloat, anchor: CGPoint) {
        let minPxX = viewPortHandler.contentLeft
        let maxPxX = viewPortHandler.contentRight
        let bottomPxY = viewPortHandler.contentBottom + 5
        
        let minX = transformer!.valueForTouchPoint(.init(x: minPxX, y: 0)).x
        let maxX = transformer!.valueForTouchPoint(.init(x: maxPxX, y: 0)).x
        
        dateFormatter.timeStyle = .short
        
        let startingTime = Date(timeIntervalSince1970: TimeInterval(minX))
        let timeLeftLabel = dateFormatter.string(from: startingTime)
        
        drawLabel(context: context,
                  formattedLabel: timeLeftLabel,
                  x: minPxX + 10,
                  y: bottomPxY,
                  attributes: [.foregroundColor : UIColor.aircastingGray,
                               .font: UIFont.muli(size: 14)],
                  constrainedToSize: .zero,
                  anchor: .zero,
                  angleRadians: 0)
        
        let endTime = Date(timeIntervalSince1970: TimeInterval(maxX))
        let timeRightLabel = dateFormatter.string(from: endTime)
        
        drawLabel(context: context,
                  formattedLabel: timeRightLabel,
                  x: maxPxX - 50,
                  y: bottomPxY,
                  attributes: [.foregroundColor : UIColor.aircastingGray,
                               .font: UIFont.muli(size: 14)],
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
            #warning("TODO: handle the situation when (thresholdVeryHigh - thresholdVeryLow) == 0")
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

struct Graph: UIViewRepresentable {
    typealias UIViewType = AirCastingGraph
    
    @ObservedObject var stream: MeasurementStreamEntity
    @ObservedObject var thresholds: SensorThreshold
    var isAutozoomEnabled: Bool
    
    func makeUIView(context: Context) -> AirCastingGraph {
        AirCastingGraph()
    }

    func updateUIView(_ uiView: AirCastingGraph, context: Context) {

        try? uiView.updateWithThreshold(thresholdValues: thresholds.rawThresholdsBinding.wrappedValue)
        
        let entries = stream.allMeasurements?.compactMap({ measurement -> ChartDataEntry? in
            let timeInterval = Double(measurement.time.timeIntervalSince1970)
            let chartDataEntry = ChartDataEntry(x: timeInterval, y: measurement.value)
            return chartDataEntry
        }) ?? []
        uiView.updateWithEntries(entries: entries, isAutozoomEnabled: isAutozoomEnabled)
    }
}

#if DEBUG
struct AirCastingGraph_Previews: PreviewProvider {
    static var previews: some View {
        Graph(stream: .mock, thresholds: .mock, isAutozoomEnabled: true)
    }
}
#endif
