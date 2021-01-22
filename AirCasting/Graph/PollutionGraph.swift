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
                       ChartDataEntry(x: 5, y: 7),
                       ChartDataEntry(x: 6, y: 4),
                       ChartDataEntry(x: 7, y: 25)]
        
        let dataSet = LineChartDataSet(entries: entries)
        let data = LineChartData(dataSet: dataSet)
        lineChartView.data = data
        
        //min & max yaxis values
        lineChartView.leftAxis.axisMinimum = 0
        lineChartView.leftAxis.axisMaximum = 100
        
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
        for index in colorValues.indices.reversed() {
            let value = colorValues[index]
            let yMax = gridClippingRect.maxY
            let height = CGFloat(value) * yMax / 100
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
        PollutionGraph(values: [13, 25, 67])
    }
}
