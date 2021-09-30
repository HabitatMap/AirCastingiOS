// Created by Lunar on 18/06/2021.
//

import SwiftUI
import Charts

class AirCastingGraph: UIView {
    let lineChartView = LineChartView()
    var renderer: MultiColorGridRenderer?
    var didMoveOrScaleGraph = false
    private var previousDateRange: ClosedRange<Date>? = nil
    private let onDateRangeChange: ((ClosedRange<Date>) -> Void)?
    var limitLines: [ChartLimitLine] = [] {
        didSet {
            guard oldValue != limitLines else { return }
            updateMidnightLines(with: limitLines)
        }
    }
    
    init(onDateRangeChange: ((ClosedRange<Date>) -> Void)?) {
        self.onDateRangeChange = onDateRangeChange
        super.init(frame: .zero)
        self.addSubview(lineChartView)
        lineChartView.delegate = self
        try? setupGraph()
    }
    
    private func setupGraph() throws {
        
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lineChartView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            lineChartView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            lineChartView.topAnchor.constraint(equalTo: self.topAnchor),
            lineChartView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        //set edges
        lineChartView.minOffset = 0.0
        
        //remove border lines and legend
        lineChartView.xAxis.drawLabelsEnabled = false
        
        lineChartView.leftAxis.drawLabelsEnabled = false
        lineChartView.leftAxis.drawAxisLineEnabled = false
        lineChartView.leftAxis.drawGridLinesEnabled = true
        
        lineChartView.rightAxis.enabled = false
        lineChartView.rightAxis.drawLabelsEnabled = false
        lineChartView.rightAxis.drawAxisLineEnabled = false
        
        lineChartView.legend.enabled = false
        lineChartView.scaleYEnabled = false
        
        lineChartView.xAxis.drawLabelsEnabled = false
        lineChartView.xAxis.labelCount = 2
        lineChartView.extraBottomOffset = 2
        
        lineChartView.highlightPerTapEnabled = false
        lineChartView.highlightPerDragEnabled = false
        renderer = MultiColorGridRenderer(viewPortHandler: lineChartView.viewPortHandler,
                                          yAxis: lineChartView.leftAxis,
                                          transformer: lineChartView.getTransformer(forAxis: .left))
        guard let renderer = renderer else {
            throw GraphError.rendererError
        }
        lineChartView.leftYAxisRenderer = renderer
    }
    
    private func zoomoutToThirtyMinutes(dataSet: LineChartDataSet) {
        let thirtyMinutesMeasurementCount = 60 * 30
        lineChartView.setVisibleXRangeMaximum(Double(thirtyMinutesMeasurementCount))
        lineChartView.moveViewToX(dataSet.xMax)
        //enable zoom out
        lineChartView.setVisibleXRangeMaximum(dataSet.xMax)
    }
    
    func updateWithThreshold(thresholdValues: [Float]) throws {
        guard let renderer = renderer else {
            throw GraphError.rendererError
        }
        renderer.thresholds = thresholdValues
        
        lineChartView.leftAxis.axisMinimum = Double(thresholdValues.first ?? 0)
        lineChartView.leftAxis.axisMaximum = Double(thresholdValues.last ?? 200)
        
        lineChartView.data = lineChartView.data
        lineChartView.setNeedsDisplay()
    }
    
    func updateWithEntries(entries: [ChartDataEntry], isAutozoomEnabled: Bool) {
        let dataSet = LineChartDataSet(entries: entries)
        let data = LineChartData(dataSet: dataSet)
        lineChartView.data = data
        
        //format data labels
        data.setDrawValues(false)
        
        // Line styling
        dataSet.drawCirclesEnabled = false
        dataSet.setColor(UIColor(.white))
        dataSet.mode = .linear
        dataSet.lineWidth = 4
        
        if !didMoveOrScaleGraph && isAutozoomEnabled {
            zoomoutToThirtyMinutes(dataSet: dataSet)
        }
        callDateRangeChangeObserver()
    }
    
    private func callDateRangeChangeObserver() {
        let dateRange = getCurrentDateRange()
        guard previousDateRange != dateRange else { return }
        previousDateRange = dateRange
        onDateRangeChange?(dateRange)
    }
    
    private func getCurrentDateRange() -> ClosedRange<Date> {
        let startDate = Date(timeIntervalSince1970: lineChartView.lowestVisibleX)
        let endDate = Date(timeIntervalSince1970: lineChartView.highestVisibleX)
        #warning("Please check if this is still the case")
        // Workaround for a weird quirk with Chart - when first called
        // `startDate` is sane, but `endDate` is 1970, so we need a special
        // case to fix that.
        guard startDate < endDate else {
            return startDate...(.distantFuture)
        }
        return startDate...endDate
    }
    
    private func updateMidnightLines(with limitLines: [ChartLimitLine]) {
        lineChartView.xAxis.removeAllLimitLines()
        for line in limitLines {
            lineChartView.xAxis.addLimitLine(line)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AirCastingGraph: ChartViewDelegate {
    
    // Callbacks when the chart is scaled / zoomed via pinch zoom gesture.
    @objc func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        callDateRangeChangeObserver()
        didMoveOrScaleGraph = true
    }
    // Callbacks when the chart is moved / translated via drag gesture.
    @objc func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        callDateRangeChangeObserver()
        didMoveOrScaleGraph = true
    }
}

#if DEBUG
struct AirCastingGraph_Previews: PreviewProvider {
    static var previews: some View {
        Graph(stream: .mock, thresholds: .mock, isAutozoomEnabled: true)
    }
}
#endif
