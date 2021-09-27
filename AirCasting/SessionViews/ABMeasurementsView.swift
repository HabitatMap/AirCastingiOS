// Created by Lunar on 07/06/2021.
//

import SwiftUI
import AirCastingStyling

enum MeasurementPresentationStyle {
    case showValues
    case hideValues
}

struct ABMeasurementsView<VM: SyncingMeasurementsViewModel>: View {
    var viewModelProvider: () -> VM
    @ObservedObject var session: SessionEntity
    @Binding var isCollapsed: Bool
    @Binding var selectedStream: MeasurementStreamEntity?
    var thresholds: [SensorThreshold]
    let measurementPresentationStyle: MeasurementPresentationStyle
    @State private var viewModel: VM?
    
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
        .onAppear {
            viewModel = viewModelProvider()
        }
    }
}

struct _ABMeasurementsView: View {
    
    @ObservedObject var measurementsViewModel: DefaultSyncingMeasurementsViewModel
    @ObservedObject var session: SessionEntity
    @Binding var isCollapsed: Bool
    @Binding var selectedStream: MeasurementStreamEntity?
    
    var thresholds: [SensorThreshold]
    let measurementPresentationStyle: MeasurementPresentationStyle
    
    @EnvironmentObject var selectedSection: SelectSection
    
    private var streamsToShow: [MeasurementStreamEntity] {
        return session.sortedStreams ?? []
    }
    
    var body: some View {
        let streams = streamsToShow
        let hasAnyMeasurements = streams.filter { $0.latestValue != nil }.count > 0
        
        return Group {
            if hasAnyMeasurements {
                VStack(alignment: .leading, spacing: 5) {
                    measurementsTitle
                        .font(Font.moderate(size: 12))
                        .padding(.bottom, 3)
                    HStack {
                        Group {
                            ForEach(streams, id : \.self) { stream in
                                if let threshold = thresholds.threshold(for: stream) {
                                    SingleMeasurementView(stream: stream,
                                                          value: stream.latestValue ?? 0,
                                                          threshold: threshold,
                                                          selectedStream: _selectedStream,
                                                          measurementPresentationStyle: measurementPresentationStyle)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                if session.isFollowed {
                    SessionLoadingView()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        measurementsTitle
                            .font(Font.moderate(size: 12))
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
                ForEach(streamsToShow, id : \.self) { stream in
                    SingleMeasurementView(stream: stream,
                                          value: nil,
                                          threshold: nil,
                                          selectedStream: .constant(nil),
                                          measurementPresentationStyle: .hideValues)
                }
            }.padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension _ABMeasurementsView {
    var measurementsTitle: some View {
        if session.deviceType == .MIC {
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
        }
        return Text("")
    }
}
