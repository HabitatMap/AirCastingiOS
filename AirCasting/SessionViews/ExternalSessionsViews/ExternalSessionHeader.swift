// Created by Lunar on 05/05/2022.
//

import SwiftUI

struct ExternalSessionHeader: View {
    var session: Sessionable
    @ObservedObject var thresholds: ABMeasurementsViewThreshold
    @Binding var selectedStream: MeasurementStreamEntity?
    @Binding var isCollapsed: Bool
    let expandingAction: (() -> Void)?
    @State var chevronIndicator = "chevron.down"

    var streams: [MeasurementStreamEntity] {
        session.sortedStreams
    }

    var body: some View {
        VStack {
            sessionHeader
            measurements
        }
    }
}


private extension ExternalSessionHeader {
    var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                dateAndTime
                    .foregroundColor(Color.aircastingTimeGray)
            }
            nameLabel
        }
        .font(Fonts.regularHeading4)
        .foregroundColor(.aircastingGray)
    }

    var dateAndTime: some View {
        adaptTimeAndDate()
    }

    var nameLabel: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(session.name ?? "")
                    .font(Fonts.regularHeading1)
                Spacer()
                if let action = expandingAction {
                    Button(action: {
                        action()
                        chevronIndicator = chevronIndicator == "chevron.down" ? "chevron.up" : "chevron.down"
                    }) {
                        Image(systemName: chevronIndicator)
                            .renderingMode(.original)
                    }
                }
            }
            sensorType
                .font(Fonts.regularHeading4)
        }
        .foregroundColor(.darkBlue)
    }

    var sensorType: some View {
        let allStreams = session.allStreams
        return SessionTypeIndicator(sessionType: .fixed, streamSensorNames: allStreams.compactMap(\.sensorPackageName))
    }


    func adaptTimeAndDate() -> Text {
        let formatter = DateFormatters.SessionCartView.utcDateIntervalFormatter

        let start = session.startTime ?? DateBuilder.getFakeUTCDate()
        let end = session.endTime ?? DateBuilder.getFakeUTCDate()

        let string = formatter.string(from: start, to: end)
        return Text(string)
    }

    var measurements: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.SessionCart.lastMinuteMeasurement)
                .font(Fonts.moderateTitle1)
                .padding(.bottom, 3)
            HStack {
                streams.count != 1 ? Spacer() : nil
                ForEach(streams, id : \.id) { stream in
                    if let threshold = thresholds.value.threshold(for: stream.sensorName ?? "") {
                        SingleMeasurementView(stream: stream,
                                              threshold: SingleMeasurementViewThreshold(value: threshold),
                                              selectedStream: $selectedStream,
                                              isCollapsed: $isCollapsed,
                                              measurementPresentationStyle: .showValues,
                                              isDormant: false)
                    }
                    Spacer()
                }
            }
        }
    }
}
