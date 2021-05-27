//
//  MeasurementChart.swift
//  AirCasting
//
//  Created by Lunar on 11/01/2021.
//

import SwiftUI
import Charts

class UI_PollutionChart: UIView {
    let lineChartView = LineChartView()
    
    init() {
        super.init(frame: .zero)
        
//        let lineChartView = LineChartView()
        self.addSubview(lineChartView)
        
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lineChartView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            lineChartView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            lineChartView.topAnchor.constraint(equalTo: self.topAnchor),
            lineChartView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
//        var entriesForDrawing = entries
//        entriesForDrawing.sort { (e1, e2) -> Bool in
//            e1.x < e2.x
//        }
//
//        let dataSet = LineChartDataSet(entries: entriesForDrawing)
//        let data = LineChartData(dataSet: dataSet)
//        lineChartView.data = data
//
//        //format data labels
//        let formatter = NumberFormatter()
//        formatter.maximumFractionDigits = 0
//        data.setValueFormatter(DefaultValueFormatter(formatter: formatter))
//        data.setValueFont(UIFont(name: "Muli-Regular", size: 12)!)
//        data.setValueTextColor(UIColor(.aircastingGray))
        
        //remove border lines and legend
        lineChartView.xAxis.enabled = false
        lineChartView.xAxis.drawLabelsEnabled = false
        lineChartView.xAxis.drawGridLinesEnabled = false
        lineChartView.xAxis.axisMinimum = 0
        lineChartView.xAxis.axisMaximum = 9
        
        lineChartView.leftAxis.drawLabelsEnabled = false
        lineChartView.leftAxis.drawAxisLineEnabled = false
        lineChartView.leftAxis.gridColor = UIColor(.aircastingGray).withAlphaComponent(0.4)
        #warning("this doesn't work so change it")
        lineChartView.leftAxis.spaceMax = 1.5
        lineChartView.leftAxis.spaceMin = 15
        
        lineChartView.rightAxis.enabled = false
//        lineChartView.rightAxis.drawLabelsEnabled = false
//        lineChartView.rightAxis.drawAxisLineEnabled = false
        
        lineChartView.legend.enabled = false
        
        //disable zooming
        lineChartView.setScaleEnabled(false)
        
        
//        //dots colors
//        dataSet.circleHoleColor = UIColor(.aircastingGreen)
//        dataSet.setCircleColors(UIColor(.aircastingGreen).withAlphaComponent(0.5))
//        //line color
//        dataSet.setColor(UIColor(.aircastingGray).withAlphaComponent(0.7))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ChartView: UIViewRepresentable {
    
//    @ObservedObject var measurementStream: MeasurementStreamEntity
//    @ObservedObject var session: SessionEntity
//    @ObservedObject var thresholds: SensorThreshold
    
    var entries: [ChartDataEntry] = [
                        ChartDataEntry(x: 0, y: 4),
                        ChartDataEntry(x: 1, y: 0),
                        ChartDataEntry(x: 2, y: 5),
                        ChartDataEntry(x: 3, y: 1)
            ]
    var thresholds: SensorThreshold
    
    typealias UIViewType = UI_PollutionChart
    
    func makeUIView(context: Context) -> UI_PollutionChart {
        UI_PollutionChart()
    }
    
    func updateUIView(_ uiView: UI_PollutionChart, context: Context) {
        var entriesForDrawing = entries
        entriesForDrawing.sort { (e1, e2) -> Bool in
            e1.x < e2.x
        }
        
        let dataSet = LineChartDataSet(entries: entriesForDrawing)
        let data = LineChartData(dataSet: dataSet)
        uiView.lineChartView.data = data
        
        //format data labels
        formatData(data: data)
        
        //format line and dots
        formatDataSet(dataSet: dataSet)
    }
    
    func formatData(data: LineChartData) {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        data.setValueFormatter(DefaultValueFormatter(formatter: formatter))
        data.setValueFont(UIFont(name: "Muli-Regular", size: 12)!)
        data.setValueTextColor(UIColor(.aircastingGray))
    }
    
    func formatDataSet(dataSet: LineChartDataSet) {
        //dots colors
        dataSet.circleColors = generateColorsSet(for: dataSet.entries)
        dataSet.drawCircleHoleEnabled = false
        dataSet.circleRadius = 6
        
        //line color
        dataSet.setColor(UIColor(.aircastingGray).withAlphaComponent(0.7))
    }
    
    func generateColorsSet(for entries: [ChartDataEntry]) -> [UIColor] {
        var colors: [UIColor] = []
        for entry in entries {
            switch Int32(entry.y) {
            case thresholds.thresholdVeryLow..<thresholds.thresholdLow:
                colors.append(UIColor.aircastingGreen.withAlphaComponent(0.5))
            case thresholds.thresholdLow..<thresholds.thresholdMedium:
                colors.append(UIColor.aircastingYellow.withAlphaComponent(0.5))
            case thresholds.thresholdMedium..<thresholds.thresholdHigh:
                colors.append(UIColor.aircastingOrange.withAlphaComponent(0.5))
            default:
                colors.append(UIColor.aircastingRed.withAlphaComponent(0.5))
            }
        }
        return colors
    }
}

//struct MeasurementChart_Previews: PreviewProvider {
//    static var previews: some View {
//        ChartView()
//            .frame(width: 300, height: 250, alignment: .center)
//    }
//}
