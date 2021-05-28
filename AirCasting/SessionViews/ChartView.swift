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
        
        self.addSubview(lineChartView)
        
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lineChartView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            lineChartView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            lineChartView.topAnchor.constraint(equalTo: self.topAnchor),
            lineChartView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        //remove border lines and legend
        lineChartView.xAxis.enabled = true
        lineChartView.xAxis.drawLabelsEnabled = false
        lineChartView.xAxis.labelPosition = .bottom
        lineChartView.xAxis.drawGridLinesEnabled = false
        lineChartView.xAxis.axisMinimum = 0
        lineChartView.xAxis.axisMaximum = 9
        
        lineChartView.leftAxis.drawLabelsEnabled = false
        lineChartView.leftAxis.drawAxisLineEnabled = false
        lineChartView.leftAxis.gridColor = UIColor(.aircastingGray).withAlphaComponent(0.4)
        
        lineChartView.rightAxis.enabled = false
        
        lineChartView.legend.enabled = false
        
        #warning("The text is not appearing and I don't know why")
        lineChartView.noDataText = "Wait for the averages to appear"
        lineChartView.noDataTextColor = .red
        lineChartView.noDataTextAlignment = .center
        
        //disable zooming
        lineChartView.setScaleEnabled(false)
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ChartView: UIViewRepresentable {
    
    @ObservedObject var stream: MeasurementStreamEntity
    var thresholds: SensorThreshold
    
    typealias UIViewType = UI_PollutionChart
    
    func makeUIView(context: Context) -> UI_PollutionChart {
        UI_PollutionChart()
    }
    
    func updateUIView(_ uiView: UI_PollutionChart, context: Context) {
        let chartCreator = ChartEntriesCreator(stream: stream)
        var entriesForDrawing = chartCreator.generateEntries()
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

struct MeasurementChart_Previews: PreviewProvider {
    static var previews: some View {
        ChartView(stream: .mock, thresholds: .mock)
            .frame(width: 300, height: 250, alignment: .center)
    }
}
