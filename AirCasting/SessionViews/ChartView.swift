// Created by Lunar on 19/02/2022.
//

import SwiftUI

struct ChartView: View {
    @ObservedObject private var thresholds: ABMeasurementsViewThreshold
    @StateObject private var viewModel: ChartViewModel
    @Binding private var stream: MeasurementStreamEntity?
    
    init(thresholds: ABMeasurementsViewThreshold, stream: Binding<MeasurementStreamEntity?>, session: SessionEntity) {
        self.thresholds = thresholds
        self._stream = .init(projectedValue: stream)
        self._viewModel = .init(wrappedValue: .init(session: session, stream: stream.wrappedValue))
    }
    
    var body: some View {
        UIKitChartView(thresholds: thresholds.value,
                       viewModel: viewModel)
            .frame(height: 120)
            .disabled(true)
            .onChange(of: stream) { newValue in
                viewModel.stream = newValue
            }
        HStack() {
            startTime
            Spacer()
            descriptionText(stream: stream)
            Spacer()
            endTime
        }
    }
    
    var startTime: some View {
        let formatter = DateFormatters.SessionCartView.pollutionChartDateFormatter

        guard let start = viewModel.chartStartTime else { return Text("") }

        let string = formatter.string(from: start)
        return Text(string)
    }

    var endTime: some View {
        let formatter = DateFormatters.SessionCartView.pollutionChartDateFormatter

        let end = viewModel.chartEndTime ?? DateBuilder.getFakeUTCDate()

        let string = formatter.string(from: end)
        return Text(string)
    }
    
    func descriptionText(stream: MeasurementStreamEntity?) -> some View {
        guard let stream = stream else { return Text("") }
        return Text("\(stream.session.isMobile ? Strings.SessionCartView.avgSessionMin : Strings.SessionCartView.avgSessionH) \(stream.unitSymbol ?? "")")
    }
}
