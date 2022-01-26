import SwiftUI
import AirCastingStyling

enum MeasurementPresentationStyle {
    case showValues
    case hideValues
}

struct ABMeasurementsView<VM: SyncingMeasurementsViewModel>: View {
    @ObservedObject var session: SessionEntity
    @Binding var isCollapsed: Bool
    @Binding var selectedStream: MeasurementStreamEntity?
    var thresholds: [SensorThreshold]
    let measurementPresentationStyle: MeasurementPresentationStyle
    @StateObject var viewModel: VM
    
    var body: some View {
        ZStack {
            if let viewModel = viewModel {
                _ABMeasurementsView(measurementsViewModel: viewModel as! DefaultSyncingMeasurementsViewModel,
                                    session: session,
                                    isCollapsed: $isCollapsed,
                                    selectedStream: $selectedStream,
                                    thresholds: thresholds,
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
    
    var thresholds: [SensorThreshold]
    let measurementPresentationStyle: MeasurementPresentationStyle
    
    @EnvironmentObject var selectedSection: SelectSection
    @EnvironmentObject var userSettings: UserSettings
    
    private var streamsToShow: [MeasurementStreamEntity] {
        return session.sortedStreams ?? []
    }
    
    var body: some View {
        let hasAnyMeasurements = streamsToShow.filter { $0.latestValue != nil }.count > 0
        
        return Group {
            if hasAnyMeasurements {
                VStack(alignment: .leading, spacing: 5) {
                    measurementsTitle
                        .font(Fonts.moderateTitle1)
                        .padding(.bottom, 3)
                    HStack {
                        streamsToShow.count != 1 ? Spacer() : nil
                        ForEach(streamsToShow.filter({ !$0.gotDeleted }), id : \.self) { stream in
                            if let threshold = thresholds.threshold(for: stream) {
                                SingleMeasurementView(stream: stream,
                                                      threshold: threshold,
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
                            .font(Fonts.moderateTitle1)
                        streamNames
                        if session.type == .mobile && session.deviceType == .AIRBEAM3 {
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
        .onChange(of: isCollapsed, perform: { new in
            if isCollapsed == false && !hasAnyMeasurements {
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
                                          threshold: nil,
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
        } else if session.type == .mobile && session.deviceType == .AIRBEAM3 {
            return Text(Strings.SessionCart.measurementsTitle)
        }
        return Text("")
    }
}
