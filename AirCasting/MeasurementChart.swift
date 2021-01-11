//
//  MeasurementChart.swift
//  AirCasting
//
//  Created by Lunar on 11/01/2021.
//

import SwiftUI
import Charts

class UI_MeasurementChart: UIView {
    
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
        let entries = [ChartDataEntry(x: 1, y: 3),
                              ChartDataEntry(x: 2, y: 2),
                              ChartDataEntry(x: 3, y: 4),
                              ChartDataEntry(x: 4, y: 2)]
        let dataSet = LineChartDataSet(entries: entries)
        dataSet.mode = .cubicBezier
        lineChartView.data = LineChartData(dataSet: dataSet)
        
        
        //remove lines and legend
        lineChartView.xAxis.drawLabelsEnabled = false
        lineChartView.xAxis.drawGridLinesEnabled = false
        lineChartView.leftAxis.drawLabelsEnabled = false
        lineChartView.leftAxis.drawAxisLineEnabled = false
        lineChartView.rightAxis.drawLabelsEnabled = false
        lineChartView.rightAxis.drawAxisLineEnabled = false
        lineChartView.legend.enabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct MeasurementChart: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        UI_MeasurementChart()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

struct MeasurementChart_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementChart()
            .frame(width: 300, height: 300, alignment: .center)
    }
}
