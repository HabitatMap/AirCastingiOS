// Created by Lunar on 05/05/2022.
//

import SwiftUI
import Resolver

struct ExternalSessionHeader: View {
    var session: Sessionable
    @ObservedObject var thresholds: ABMeasurementsViewThreshold
    @Binding var selectedStream: MeasurementStreamEntity?
    @Binding var isCollapsed: Bool
    let expandingAction: (() -> Void)?
    @State var chevronIndicator = "chevron.down"
    @State var showThresholdAlertModal = false

    var streams: [MeasurementStreamEntity] {
        session.sortedStreams
    }

    var body: some View {
        VStack {
            sessionHeader
            measurements
        }
        .sheet(isPresented: $showThresholdAlertModal) {
            thresholdAlertSheet
        }
        .onChange(of: isCollapsed, perform: { _ in
            isCollapsed ? (chevronIndicator = "chevron.down") :  (chevronIndicator = "chevron.up")
        })
    }
}


private extension ExternalSessionHeader {
    var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                dateAndTime
                    .foregroundColor(Color.aircastingTimeGray)
                Spacer()
                actionsMenu
            }
            nameLabel
        }
        .font(Fonts.moderateRegularHeading4)
        .foregroundColor(.aircastingGray)
    }

    var dateAndTime: some View {
        adaptTimeAndDate()
    }

    var nameLabel: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(session.name ?? "")
                    .font(Fonts.moderateMediumHeading1)
                Spacer()
                if let action = expandingAction {
                    Button(action: {
                        action()
                    }) {
                        Image(systemName: chevronIndicator)
                            .renderingMode(.original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                    }
                }
            }
            sensorType
                .font(Fonts.moderateRegularHeading4)
        }
        .foregroundColor(.darkBlue)
    }

    var sensorType: some View {
        let allStreams = session.allStreams
        return SessionTypeIndicator(sessionType: .fixed, streamSensorNames: allStreams.compactMap(\.sensorPackageName))
    }


    func adaptTimeAndDate() -> Text {
        let formatter: DateIntervalFormatter = DateFormatters.SessionCardView.shared.utcDateIntervalFormatter
        let start = session.startTime ?? DateBuilder.getFakeUTCDate()
        let end = session.endTime ?? DateBuilder.getFakeUTCDate()

        let string = formatter.string(from: start, to: end)
        return Text(string)
    }
    
    var actionsMenu: some View {
        Menu {
            actionsMenuThresholdAlertButton
        } label: {
            ZStack(alignment: .trailing) {
                EditButtonView()
                Rectangle()
                    .frame(width: 50, height: 35, alignment: .trailing)
                    .opacity(0.0001)
            }
        }
    }
    
    var actionsMenuThresholdAlertButton: some View {
        Button {
            showThresholdAlertModal.toggle()
        } label: {
            Label(Strings.SessionHeaderView.thresholdAlertsButton, systemImage: "exclamationmark.triangle")
        }
    }
    
    var thresholdAlertSheet: some View {
        ThresholdAlertSheet(viewModel: ThresholdAlertSheetViewModel(session: session), isActive: $showThresholdAlertModal)
    }

    var measurements: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Strings.SessionCart.lastMinuteMeasurement)
                .font(Fonts.moderateRegularHeading4)
                .foregroundColor(.aircastingGray)
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
