// Created by Lunar on 28/02/2022.
//

import SwiftUI
import Charts

struct SearchAndFollowChartView: UIViewRepresentable {
    @StateObject var viewModel: SearchAndFollowChartViewModel
    
    typealias UIViewType = UI_PollutionChart
    
    init(viewModel: SearchAndFollowChartViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }
    
    func makeUIView(context: Context) -> UI_PollutionChart {
        UI_PollutionChart()
    }
    
    func updateUIView(_ uiView: UI_PollutionChart, context: Context) {
        guard !viewModel.entries.isEmpty else { return }
        
        var entries = viewModel.entries
        
        entries.sort { (e1, e2) -> Bool in
            e1.x < e2.x
        }
        
        let dataSet = LineChartDataSet(entries: entries)
        let data = LineChartData(dataSet: dataSet)
        uiView.lineChartView.data = data
        
        // format data labels
        formatData(data: data)
        
        // format line and dots
        formatDataSet(dataSet: dataSet)
    }
    
    private func formatData(data: LineChartData) {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        data.setValueFormatter(DefaultValueFormatter(formatter: formatter))
        data.setValueFont(Fonts.muliHeadingUIFont2)
        data.setValueTextColor(UIColor.aircastingGray)
    }
    
    private func formatDataSet(dataSet: LineChartDataSet) {
        // dots colors
        dataSet.circleColors = generateColorsSet(for: dataSet.entries)
        dataSet.drawCircleHoleEnabled = false
        dataSet.circleRadius = 4
        
        // line color
        dataSet.setColor(UIColor.aircastingGray.withAlphaComponent(0.7))
    }
    
    private func generateColorsSet(for entries: [ChartDataEntry]) -> [UIColor] {
        [.aircastingGray]
    }
}
