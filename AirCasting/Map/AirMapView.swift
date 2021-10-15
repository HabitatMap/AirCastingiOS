//
//  Map.swift
//  AirCasting
//
//  Created by Lunar on 25/01/2021.
//

import SwiftUI
import CoreLocation
import Foundation
import CoreData

struct AirMapView: View {
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.presentationMode) var presentationMode
    
    var thresholds: [SensorThreshold]
    @StateObject var statsContainerViewModel: StatisticsContainerViewModel
    @StateObject var mapStatsDataSource: MapStatsDataSource
    let session: SessionEntity
    @Binding var showLoadingIndicator: Bool

    @Binding var selectedStream: MeasurementStreamEntity?
    let sessionStoppableFactory: SessionStoppableFactory
    let measurementStreamStorage: MeasurementStreamStorage
    
    private var pathPoints: [PathPoint] {
        return selectedStream?.allMeasurements?.compactMap {
            #warning("TODO: Do something with no location points")
            guard let location = $0.location else { return nil }
            return PathPoint(location: location, measurementTime: $0.time, measurement: $0.value)
        } ?? []
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 20) {
            HStack {
                backButton
                SessionHeaderView(action: {},
                                  isExpandButtonNeeded: false,
                                  isSensorTypeNeeded: false,
                                  isCollapsed: Binding.constant(false),
                                  session: session,
                                  sessionStopperFactory: sessionStoppableFactory)
            }
            ABMeasurementsView(viewModelProvider: { DefaultSyncingMeasurementsViewModel(measurementStreamStorage: measurementStreamStorage,
                                                                              sessionDownloader: SessionDownloadService(client: URLSession.shared,
                                                                                                                        authorization: UserAuthenticationSession(),
                                                                                                                        responseValidator: DefaultHTTPResponseValidator()),
                                                                              session: session)
            },
                               session: session,
                               isCollapsed: Binding.constant(false),
                               selectedStream: $selectedStream,
                               thresholds: thresholds,
                               measurementPresentationStyle: .showValues)

            if let threshold = thresholds.threshold(for: selectedStream) {
                if !showLoadingIndicator {
                    ZStack(alignment: .topLeading) {
                        GoogleMapView(pathPoints: pathPoints,
                                      threshold: threshold, placePickerDismissed: Binding.constant(false))
                            .onPositionChange { [weak mapStatsDataSource, weak statsContainerViewModel] visiblePoints in
                                mapStatsDataSource?.visiblePathPoints = visiblePoints
                                statsContainerViewModel?.adjustForNewData()
                            }
                        // Statistics container shouldn't be presented in mobile dormant tab
                        if !(session.type == .mobile && session.isActive == false) {
                            StatisticsContainerView(statsContainerViewModel: statsContainerViewModel,
                                                    threshold: threshold)
                        }
                    }
                    NavigationLink(destination: HeatmapSettingsView(changedThresholdValues: threshold.rawThresholdsBinding)) {
                        EditButtonView()
                    }
                    ThresholdsSliderView(threshold: threshold)
                        // Fixes labels covered by tabbar
                        .padding(.bottom)
                } else {
                    Spacer()
                }
            }
        }
//        .onChange(of: selectedStream) { newStream in
////            mapStatsDataSource.stream = newStream
//            statsContainerViewModel.adjustForNewData()
//            print("## Called adjusting data")
//        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background, .inactive: self.presentationMode.wrappedValue.dismiss()
            case .active: break
            @unknown default: fatalError()
            }
        }
        .padding()
    }
    
    var backButton: some View {
        Button {
            self.presentationMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: "chevron.backward")
                .foregroundColor(.black)
        }
        .padding()
    }
}

#if DEBUG
struct Map_Previews: PreviewProvider {
    static var previews: some View {
        AirMapView(thresholds: [SensorThreshold.mock],
                   statsContainerViewModel: StatisticsContainerViewModel(statsInput: MeasurementsStatisticsInputMock()),
                   mapStatsDataSource: MapStatsDataSource(),
                   session: .mock,
                   showLoadingIndicator: .constant(true),
                   selectedStream: .constant(nil),
                   sessionStoppableFactory: SessionStoppableFactoryDummy(),
                   measurementStreamStorage: PreviewMeasurementStreamStorage())
    }
}

struct MeasurementsStatisticsInputMock: MeasurementsStatisticsInput {
    func computeStatistics() { }
}
#endif
