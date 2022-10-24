// Created by Lunar on 18/06/2021.
//

import SwiftUI
import Charts

class AirCastingGraph: UIView {
    typealias NoteTap = (Note) -> Void
    private typealias NoteButtonData = (button: UIButton, note: Note, onTap: NoteTap)
    let lineChartView = LineChartView()
    var renderer: MultiColorGridRenderer?
    var didMoveOrScaleGraph = false
    private var noteButtons: [NoteButtonData] = []
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
        // set edges
        lineChartView.minOffset = 0.0
        
        // remove border lines and legend
        lineChartView.xAxis.drawLabelsEnabled = false
        
        lineChartView.leftAxis.drawLabelsEnabled = false
        lineChartView.leftAxis.drawAxisLineEnabled = false
        lineChartView.leftAxis.drawGridLinesEnabled = true
        
        lineChartView.rightAxis.enabled = false
        lineChartView.rightAxis.drawLabelsEnabled = false
        lineChartView.rightAxis.drawAxisLineEnabled = false
        
        lineChartView.legend.enabled = false
        lineChartView.scaleYEnabled = false
        
        lineChartView.xAxis.drawLabelsEnabled = true
        lineChartView.xAxis.labelCount = 2
        lineChartView.extraBottomOffset = 25
        lineChartView.extraTopOffset = -15 // To make graph lines close to the top
        
        lineChartView.highlightPerTapEnabled = false
        lineChartView.highlightPerDragEnabled = false
        
        lineChartView.xAxisRenderer = TimeAxisRenderer(viewPortHandler: lineChartView.viewPortHandler,
                                                       xAxis: lineChartView.xAxis,
                                                       transformer: lineChartView.getTransformer(forAxis: .left))
        
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
        // enable zoom out
        lineChartView.setVisibleXRangeMaximum(dataSet.xMax)
    }
    
    func updateWithThreshold(thresholdValues: [Float]) throws {
        guard let renderer = renderer else {
            throw GraphError.rendererError
        }
        renderer.thresholds = thresholdValues
        
        lineChartView.leftAxis.axisMinimum = Double(thresholdValues.first ?? 0)
        lineChartView.leftAxis.axisMaximum = Double(thresholdValues.last ?? 200) + 0.5
        // added 0.5 not to change line width when axisMaximum == Peak
        
        lineChartView.data = lineChartView.data
        lineChartView.setNeedsDisplay()
    }
    
    func updateWithEntries(entries: [ChartDataEntry], isAutozoomEnabled: Bool) {
        let dataSet = LineChartDataSet(entries: entries)
        let data = LineChartData(dataSet: dataSet)
        lineChartView.data = data
        
        // format data labels
        data.setDrawValues(false)
        
        // Line styling
        dataSet.drawCirclesEnabled = false
        dataSet.setColor(UIColor(.white))
        dataSet.mode = .cubicBezier
        dataSet.lineWidth = 4
        
        if !didMoveOrScaleGraph && isAutozoomEnabled {
            zoomoutToThirtyMinutes(dataSet: dataSet)
        }
        layoutNotes()
        callDateRangeChangeObserver()
    }
    
    private func callDateRangeChangeObserver() {
        let dateRange = getCurrentDateRange()
        guard previousDateRange != dateRange else { return }
        previousDateRange = dateRange
        onDateRangeChange?(dateRange)
    }
    
    private func getCurrentDateRange() -> ClosedRange<Date> {
        let startDate = DateBuilder.getDateWithTimeIntervalSince1970(lineChartView.lowestVisibleX)
        let endDate = DateBuilder.getDateWithTimeIntervalSince1970(lineChartView.highestVisibleX)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutNotes()
    }
}

extension AirCastingGraph: ChartViewDelegate {
    
    // Callbacks when the chart is scaled / zoomed via pinch zoom gesture.
    @objc func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        callDateRangeChangeObserver()
        didMoveOrScaleGraph = true
        layoutNotes()
    }
    // Callbacks when the chart is moved / translated via drag gesture.
    @objc func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        callDateRangeChangeObserver()
        didMoveOrScaleGraph = true
        layoutNotes()
    }
}

// MARK: - Notes handling

extension AirCastingGraph {
    
    func setupNotes(_ notes: [Note], onTap: @escaping NoteTap) {
        assert(Thread.isMainThread)
        noteButtons.forEach { $0.button.removeFromSuperview() }
        noteButtons = notes.map { (createNewNoteButton(), $0, onTap) }
        noteButtons.forEach { lineChartView.addSubview($0.button) }
        setNeedsLayout()
    }
    
    private func createNewNoteButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "message-square"), for: .normal)
        button.addTarget(self, action: #selector(noteTapped), for: .touchUpInside)
        return button
    }
    
    @objc private func noteTapped(sender: UIButton!) {
        guard let buttonData = noteButtons.first(where: { button, _, _ in button === sender }) else {
            Log.error("Tapped note button, but no button found in mapping!")
            return
        }
        buttonData.onTap(buttonData.note)
    }
    
    private func layoutNotes() {
        guard let dataSet = getChartDataSet() else { return }
        noteButtons.forEach { $0.button.isHidden = true }
        let visibleNotes = onScreenButtons(dataSet: dataSet)
        visibleNotes.forEach { button, note, _ in
            guard let frame = calculateButtonFrame(for: note, in: dataSet) else { return }
            button.isHidden = false
            button.frame = frame
        }
    }
    
    private func getChartDataSet() -> IChartDataSet? {
        guard let data = lineChartView.data else {
            Log.error("Couldn't get data from graph!")
            return nil
        }
        assert(data.dataSetCount == 1)
        return data.dataSets[0]
    }
    
    private func visibleRangeForXAxis(with dataSet: IChartDataSet) -> ClosedRange<Double> {
        if lineChartView.lowestVisibleX < lineChartView.highestVisibleX {
            return { lineChartView.lowestVisibleX...lineChartView.highestVisibleX }()
        } else if dataSet.xMin <= dataSet.xMax {
            return { dataSet.xMin...dataSet.xMax }()
        } else {
            return { dataSet.xMax...dataSet.xMin }()
        }
    }
    
    private func onScreenButtons(dataSet: IChartDataSet) -> [NoteButtonData] {
        let visibleRange = visibleRangeForXAxis(with: dataSet)
        return noteButtons.filter { _, note, _ in
            visibleRange.contains(xAxisValue(for: note))
        }
    }
    
    private func calculateButtonFrame(for note: Note, in dataSet: IChartDataSet) -> CGRect? {
        let xValue = xAxisValue(for: note)
        guard let entry = dataSet.entryForXValue(xValue, closestToY: 0.0) else {
            Log.error("Cannot match xvalue for note: \(note)")
            return nil
        }
        let yValue = Double(entry.yValue)
        let position = lineChartView.pixelForValues(x: xValue, y: yValue, axis: YAxis.AxisDependency.left)
        let buttonSize = 20.0
        return CGRect(x: position.x, y: position.y - buttonSize, width: buttonSize, height: buttonSize)
    }
    
    private func xAxisValue(for note: Note) -> Double {
        Double(note.date.timeIntervalSince1970)
    }
}
