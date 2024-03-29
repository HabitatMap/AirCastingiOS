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
    
    func makeUIView(context: Context) -> UIViewType {
        UIViewType(addMoreSpace: true)
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        guard !viewModel.entries.isEmpty else { return }
        
        let entries = viewModel.entries.map { dot -> ChartDataEntry in
            ChartDataEntry(x: dot.xPosition, y: round(dot.value))
        }
        
        let dataSet = LineChartDataSet(entries: entries)
        let data = LineChartData(dataSet: dataSet)
        uiView.lineChartView.data = data
        
        // format data labels
        formatData(data: data)
        
        // format line and dots
        let colors = viewModel.entries.map(\.color).map({ UIColor($0) })
        formatDataSet(dataSet: dataSet, colors: colors)
    }
    
    private func formatData(data: LineChartData) {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        data.setValueFormatter(DefaultValueFormatter(formatter: formatter))
        data.setValueFont(Fonts.muliRegularHeadingUIFont2)
        data.setValueTextColor(UIColor.aircastingGray)
        data.highlightEnabled = false
    }
    
    private func formatDataSet(dataSet: LineChartDataSet, colors: [UIColor]) {
        // dots colors
        dataSet.circleColors = colors
        dataSet.drawCircleHoleEnabled = false
        dataSet.circleRadius = 4
        
        // line color
        dataSet.setColor(UIColor.aircastingGray.withAlphaComponent(0.7))
    }
}
