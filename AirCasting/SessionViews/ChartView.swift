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
    let timeFormatter: DateFormatter = DateFormatters.SessionCardView.shared.pollutionChartDateFormatter

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
            return Text("\(averageLabel(for: session)) \(formatter.unitString(for: stream))")
        }
        return Text("\(Strings.SessionCartView.avgSessionH) \(formatter.unitString(for: stream))")
    }

    /// Chart averaging-window label. Fixed sessions average over 1 hr; mobile
    /// sessions over 1 min, except V2 mobile sessions configured with a coarser
    /// native interval (5 or 10 min), which average over that window.
    private func averageLabel(for session: SessionEntity) -> String {
        guard session.isMobile else { return Strings.SessionCartView.avgSessionH }
        if session.deviceFirmwareVersion == .v2 {
            switch session.nativeMeasurementIntervalSeconds {
            case 300: return Strings.SessionCartView.avgSession5Min
            case 600: return Strings.SessionCartView.avgSession10Min
            default: break
            }
        }
        return Strings.SessionCartView.avgSessionMin
    }
}
