// Created by Lunar on 19/02/2022.
//

import SwiftUI
import Resolver

struct ChartView: View {
    @InjectedObject private var userSettings: UserSettings
    @Injected private var formatter: UnitFormatter
    @ObservedObject private var thresholds: ABMeasurementsViewThreshold
    @StateObject private var viewModel: ChartViewModel
    @Binding private var stream: MeasurementStreamEntity?
    var timeFormatter: DateFormatter {
        if userSettings.twentyFourHour {
            return DateFormatters.SessionCardView.pollutionChartDateFormatter
        }
        return  DateFormatters.SessionCardView.pollutionChartDate12hFormatter
    }


    init(thresholds: ABMeasurementsViewThreshold, stream: Binding<MeasurementStreamEntity?>, session: Sessionable) {
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
        guard let start = viewModel.chartStartTime else { return Text("") }

        let string = timeFormatter.string(from: start)
        return Text(string)
    }

    var endTime: some View {
        let end = viewModel.chartEndTime ?? DateBuilder.getFakeUTCDate()

        let string = timeFormatter.string(from: end)
        return Text(string)
    }

    func descriptionText(stream: MeasurementStreamEntity?) -> some View {
        guard let stream = stream else { return Text("") }
        if let session = stream.session {
            return Text("\(session.isMobile ? Strings.SessionCartView.avgSessionMin : Strings.SessionCartView.avgSessionH) \(formatter.unitString(for: stream))")
        }
        return Text("\(Strings.SessionCartView.avgSessionH) \(formatter.unitString(for: stream))")
    }
}
