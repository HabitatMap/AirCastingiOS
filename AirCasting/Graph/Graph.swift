//
//  PollutionGraph.swift
//  AirCasting
//
//  Created by Monika Śmiałko on 15/01/2021.
//

import SwiftUI
import Charts

class UI_PollutionGraph: UIView {
    
    let lineChartView = LineChartView()
    var renderer: MultiColorGridRenderer?
    
    init() {
        super.init(frame: .zero)
        self.addSubview(lineChartView)
                
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lineChartView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            lineChartView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            lineChartView.topAnchor.constraint(equalTo: self.topAnchor),
            lineChartView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        // Data
        #warning("TODO: Replace mocked data with data from AirBeam")
        let entries = [ChartDataEntry(x: 1, y: 1),
                       ChartDataEntry(x: 2, y: 3),
                       ChartDataEntry(x: 3, y: 15),
                       ChartDataEntry(x: 4, y: 6),
                       ChartDataEntry(x: 5, y: 170),
                       ChartDataEntry(x: 6, y: 200),
                       ChartDataEntry(x: 7, y: 150)]
        
        let dataSet = LineChartDataSet(entries: entries)
        let data = LineChartData(dataSet: dataSet)
        lineChartView.data = data
        
        //format data labels
        data.setDrawValues(false)
        
        //set edges
        lineChartView.minOffset = 0.0
        
        //remove border lines and legend
        lineChartView.xAxis.enabled = false
        lineChartView.xAxis.drawLabelsEnabled = false
        lineChartView.xAxis.drawGridLinesEnabled = false
        
        lineChartView.leftAxis.drawLabelsEnabled = false
        lineChartView.leftAxis.drawAxisLineEnabled = false
        lineChartView.leftAxis.drawGridLinesEnabled = true
        
        lineChartView.rightAxis.enabled = false
        lineChartView.rightAxis.drawLabelsEnabled = false
        lineChartView.rightAxis.drawAxisLineEnabled = false
        
        lineChartView.legend.enabled = false
        
        // Line styling
        dataSet.drawCirclesEnabled = false
        dataSet.setColor(UIColor(.white))
        dataSet.mode = .linear
        dataSet.lineWidth = 4
        
        renderer = MultiColorGridRenderer(viewPortHandler: lineChartView.viewPortHandler,
                                            yAxis: lineChartView.leftAxis,
                                            transformer: lineChartView.getTransformer(forAxis: .left))
        guard let renderer = renderer else { return }
        lineChartView.leftYAxisRenderer = renderer
    }
    
    func updateWith(thresholdValues: [Float]) throws {
        guard let renderer = renderer else {
            throw GraphError.rendererError
        }
        renderer.thresholds = thresholdValues
        
        lineChartView.leftAxis.axisMinimum = Double(thresholdValues.first ?? 0)
        lineChartView.leftAxis.axisMaximum = Double(thresholdValues.last ?? 200)
        
        lineChartView.data = lineChartView.data
        lineChartView.setNeedsDisplay()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MultiColorGridRenderer: YAxisRenderer {
    
    var thresholds: [Float] = []
   
    var colors = [UIColor(red: 182/255, green: 227/255, blue: 172/255, alpha: 1),
                  UIColor(red: 254/255, green: 239/255, blue: 195/255, alpha: 1),
                  UIColor(red: 254/255, green: 222/255, blue: 188/255, alpha: 1),
                  UIColor(red: 249/255, green: 193/255, blue: 192/255, alpha: 1)
    ]
    
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
    typealias UIViewType = UI_PollutionGraph
    
    @ObservedObject var thresholds: SensorThreshold
    
    func makeUIView(context: Context) -> UI_PollutionGraph {
        UI_PollutionGraph()
    }
    
    func updateUIView(_ uiView: UI_PollutionGraph, context: Context) {
       try? uiView.updateWith(thresholdValues: thresholds.rawThresholdsBinding.wrappedValue)
    }
}

#if DEBUG
struct PollutionGraph_Previews: PreviewProvider {
    static var previews: some View {
        Graph(thresholds: .mock)
    }
}
#endif
