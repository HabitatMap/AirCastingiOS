//
//  PollutionGraph.swift
//  AirCasting
//
//  Created by Monika Śmiałko on 15/01/2021.
//

import SwiftUI
import Charts

class UI_PollutionGraph: UIView {
    init() {
        super.init(frame: .zero)
        
        let lineChartView = LineChartView()
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
                       ChartDataEntry(x: 3, y: 2),
                       ChartDataEntry(x: 4, y: 1),
                       ChartDataEntry(x: 5, y: 2),
                       ChartDataEntry(x: 6, y: 2),
                       ChartDataEntry(x: 7, y: 3)]
        
        let dataSet = LineChartDataSet(entries: entries)
        let data = LineChartData(dataSet: dataSet)
        lineChartView.data = data
        
        //format data labels
        data.setDrawValues(false)
        
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
        dataSet.setColor(UIColor(.gray))
        dataSet.lineWidth = 3
        
        lineChartView.leftYAxisRenderer = MultiColorGridRenderer(viewPortHandler: lineChartView.viewPortHandler,
                                                                 yAxis: lineChartView.leftAxis,
                                                                 transformer: lineChartView.getTransformer(forAxis: .left))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MultiColorGridRenderer: YAxisRenderer {

    
    var values: [Float] = [12, 34, 56, 100]
    var colors = [UIColor.green, UIColor.yellow, UIColor.orange, UIColor.red]
    
    override func renderGridLines(context: CGContext) {
        
        for index in values.indices.reversed() {
            let value = values[index]
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

    func makeUIView(context: Context) -> UI_PollutionGraph {
        UI_PollutionGraph()
    }
    
    func updateUIView(_ uiView: UI_PollutionGraph, context: Context) {
    }
}

struct PollutionGraph_Previews: PreviewProvider {
    static var previews: some View {
        PollutionGraph()
            .frame(width: 300, height: 300, alignment: .center)
            .border(Color.black, width: 1)
    }
}
