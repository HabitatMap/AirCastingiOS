// Created by Lunar on 28/02/2022.
//

import SwiftUI
import Charts

struct SearchAndFollowChartView: UIViewRepresentable {
    @StateObject var viewModel: SearchAndFollowChartViewModel
    @Binding var streamID: Int?
    private var onStreamChangeAction: (() -> ())? = nil
    
    typealias UIViewType = UI_PollutionChart
    
    init(viewModel: SearchAndFollowChartViewModel, streamID: Binding<Int?>) {
        _viewModel = .init(wrappedValue: viewModel)
        self._streamID = .init(projectedValue: streamID)
    }
    
    /// Adds an action for when the chart stream is changed.
    func onStreamChange(action: @escaping () -> ()) -> Self {
        var newSelf = self
        newSelf.onStreamChangeAction = action
        return newSelf
    }
    
    func makeUIView(context: Context) -> UI_PollutionChart {
        UI_PollutionChart()
    }
    
    func updateUIView(_ uiView: UI_PollutionChart, context: Context) {
        if context.coordinator.streamIDKepper != streamID {
            viewModel.clearEntries()
            context.coordinator.streamIDKepper = streamID!
            onStreamChangeAction?()
        }
        guard !viewModel.entries.isEmpty else { return }
        
        let entries = viewModel.entries.enumerated().map { (i, dot) -> ChartDataEntry in
            ChartDataEntry(x: Double(i), y: dot.value)
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
        data.setValueFont(Fonts.muliHeadingUIFont2)
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
    
    class Coordinator: NSObject {
        var parent: SearchAndFollowChartView!
        var streamIDKepper = -1
        
        init(_ parent: SearchAndFollowChartView) {
            self.parent = parent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
        
}
