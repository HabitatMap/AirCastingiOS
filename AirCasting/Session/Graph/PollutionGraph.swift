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
        //TO DO: replace mocked data with data from AirBeam
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
        
        lineChartView.leftYAxisRenderer = MultiColorGridRenderer(viewPortHandler: lineChartView.viewPortHandler,
                                                                 yAxis: lineChartView.leftAxis,
                                                                 transformer: lineChartView.getTransformer(forAxis: .left))
    }
    
    func updateWith(values: [Float]) {
        (lineChartView.leftYAxisRenderer as! MultiColorGridRenderer).values = values
        
        //min & max yaxis values
        lineChartView.leftAxis.axisMinimum = Double(values.first ?? 0)
        lineChartView.leftAxis.axisMaximum = Double(values.last ?? 200)
        print("\(lineChartView.leftAxis.axisMinimum) - \(lineChartView.leftAxis.axisMaximum)")
        
        // Needed to redraw the chart
        lineChartView.data = lineChartView.data
        lineChartView.setNeedsDisplay()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MultiColorGridRenderer: YAxisRenderer {
    
    var values: [Float] = []
   
    var colors = [UIColor(red: 182/255, green: 227/255, blue: 172/255, alpha: 1),
                  UIColor(red: 254/255, green: 239/255, blue: 195/255, alpha: 1),
                  UIColor(red: 254/255, green: 222/255, blue: 188/255, alpha: 1),
                  UIColor(red: 249/255, green: 193/255, blue: 192/255, alpha: 1)
    ]
    
    override func renderGridLines(context: CGContext) {
        let colorValues = Array(values.dropFirst())
        let maxValue = CGFloat(values.last ?? 200)
        let minValue = CGFloat(values[0])
        for index in colorValues.indices.reversed() {
            let value = CGFloat(colorValues[index])
            let yMax = gridClippingRect.maxY
            let height = (value - minValue) * yMax / (maxValue - minValue)
            let y = yMax - height
            
            context.setFillColor(colors[index].cgColor)
            context.fill((CGRect(x: gridClippingRect.minX,
                                 y: y,
                                 width: gridClippingRect.width,
                                 height: CGFloat(height))))
        }
    }
}

struct PollutionGraph: UIViewRepresentable {
    typealias UIViewType = UI_PollutionGraph
    
    let values: [Float]
    
    func makeUIView(context: Context) -> UI_PollutionGraph {
        UI_PollutionGraph()
    }
    
    func updateUIView(_ uiView: UI_PollutionGraph, context: Context) {
        uiView.updateWith(values: values)
    }
}

struct PollutionGraph_Previews: PreviewProvider {
    static var previews: some View {
        PollutionGraph(values: [30, 60, 70, 170, 200])
    }
}
