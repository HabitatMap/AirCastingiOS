import SwiftUI
import AirCastingStyling

enum MeasurementPresentationStyle {
    case showValues
    case hideValues
}

class ABMeasurementsViewThreshold: ObservableObject {
    var value: [SensorThreshold]

    init(value: [SensorThreshold]) {
        self.value = value
    }
}

struct ABMeasurementsView<VM: SyncingMeasurementsViewModel>: View {
    @ObservedObject var session: SessionEntity
    @Binding var isCollapsed: Bool
    @Binding var selectedStream: MeasurementStreamEntity?
    @ObservedObject var thresholds: ABMeasurementsViewThreshold
    let measurementPresentationStyle: MeasurementPresentationStyle
    @StateObject var viewModel: VM
    
    var body: some View {
        ZStack {
            if let viewModel = viewModel {
                _ABMeasurementsView(measurementsViewModel: viewModel as! DefaultSyncingMeasurementsViewModel,
                                    session: session,
                                    isCollapsed: $isCollapsed,
                                    selectedStream: $selectedStream,
                                    thresholds: .init(value: thresholds.value),
                                    measurementPresentationStyle: measurementPresentationStyle)
            }
        }
    }
}

struct _ABMeasurementsView: View {
    @StateObject var measurementsViewModel: DefaultSyncingMeasurementsViewModel
    @ObservedObject var session: SessionEntity
    @Binding var isCollapsed: Bool
    @Binding var selectedStream: MeasurementStreamEntity?
    
    @ObservedObject var thresholds: ABMeasurementsViewThreshold
    let measurementPresentationStyle: MeasurementPresentationStyle
    
    @EnvironmentObject var selectedSection: SelectSection
    @EnvironmentObject var userSettings: UserSettings
    
    private var streamsToShow: [MeasurementStreamEntity] {
        return session.sortedStreams
    }
    
    private var hasAnyMeasurements: Bool {
        (session.sortedStreams).filter { $0.latestValue != nil }.count > 0
    }
    
    var body: some View {
        Group {
            if hasAnyMeasurements {
                VStack(alignment: .leading, spacing: 5) {
                    measurementsTitle
                        .font(Fonts.moderateRegularHeading5)
                        .padding(.bottom, 3)
                    HStack {
                        streamsToShow.count != 1 ? Spacer() : nil
                        ForEach(streamsToShow.filter({ !$0.gotDeleted }), id : \.self) { stream in
                            if let threshold = thresholds.value.threshold(for: stream.sensorName ?? "") {
                                SingleMeasurementView(stream: stream,
                                                      threshold: .init(value: threshold),
                                                      selectedStream: $selectedStream,
                                                      isCollapsed: $isCollapsed,
                                                      measurementPresentationStyle: measurementPresentationStyle,
                                                      isDormant: session.isDormant)
                            }
                            Spacer()
                        }
                    }
                }
            } else {
                if session.isFollowed {
                    HStack {
                        SessionLoadingView()
                        Spacer()
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        measurementsTitle
                            .font(Fonts.moderateRegularHeading5)
                        streamNames
                        if session.type == .mobile {
                            if measurementsViewModel.showLoadingIndicator {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        } else {
                            if !isCollapsed && measurementsViewModel.showLoadingIndicator {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: isCollapsed, perform: { _ in
            if isCollapsed == false && (!hasAnyMeasurements || session.isUnfollowedFixed) {
                measurementsViewModel.syncMeasurements()
            }
        })
    }
    
    private var streamNames: some View {
        return HStack {
            Group {
                streamsToShow.count != 1 ? Spacer() : nil
                ForEach(streamsToShow.filter({ !$0.gotDeleted }), id : \.self) { stream in
                    SingleMeasurementView(stream: stream,
                                          threshold: .init(),
                                          selectedStream: $selectedStream,
                                          isCollapsed: $isCollapsed,
                                          measurementPresentationStyle: .hideValues,
                                          isDormant: session.isDormant)
                    Spacer()
                }
            }
        }
    }
}

extension _ABMeasurementsView {
    var measurementsTitle: some View {
        if session.deviceType == .MIC && session.isActive {
            return Text(verbatim: Strings.SessionCart.measurementsTitle)
        } else if session.isActive {
            return Text(Strings.SessionCart.measurementsTitle)
        } else if session.isDormant {
            if isCollapsed {
                return Text(Strings.SessionCart.parametersText)
            } else {
                return Text(Strings.SessionCart.dormantMeasurementsTitle)
            }
        } else if session.isFixed && !session.isFollowed {
            if isCollapsed {
                return Text(Strings.SessionCart.parametersText)
            } else {
                return Text(Strings.SessionCart.lastMinuteMeasurement)
            }
        } else if session.isFollowed {
            return Text(Strings.SessionCart.lastMinuteMeasurement)
                .font(Fonts.moderateRegularHeading4)
        } else if session.type == .mobile && session.deviceType == .AIRBEAM3 {
            return Text(Strings.SessionCart.measurementsTitle)
                .font(Fonts.moderateRegularHeading4)
        }
        return Text("")
    }
}
