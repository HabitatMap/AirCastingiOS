// Created by Lunar on 28/01/2022.
//

import SwiftUI
import AirCastingStyling

struct ReoredringSessionCard: View {
    @State private var selectedStream: MeasurementStreamEntity?
    @ObservedObject var session: SessionEntity
    @State private var isCollapsed = true
    @EnvironmentObject var selectedSection: SelectSection
    let thresholds: [SensorThreshold]
    let measurementStreamStorage: MeasurementStreamStorage
    let urlProvider: BaseURLProvider
    
    var shouldShowValues: MeasurementPresentationStyle {
        .showValues
    }
    
    var hasStreams: Bool {
        session.allStreams != nil || session.allStreams != []
    }
    
    var body: some View {
        sessionCard
    }
    
    var sessionCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            if hasStreams {
                measurements
            } else {
                SessionLoadingView()
            }
        }
        .onAppear {
            selectDefaultStreamIfNeeded(streams: session.sortedStreams ?? [])
        }
        .onChange(of: session.sortedStreams) { newValue in
            selectDefaultStreamIfNeeded(streams: newValue ?? [])
        }
        .font(Fonts.regularHeading4)
        .foregroundColor(.aircastingGray)
        .padding()
        .background(
            Group {
                Color.white
                    .shadow(color: .sessionCardShadow, radius: 9, x: 0, y: 1)
            }
        )
    }
    
    private func selectDefaultStreamIfNeeded(streams: [MeasurementStreamEntity]) {
        if selectedStream == nil {
            selectedStream = streams.first
        }
    }
}

private extension ReoredringSessionCard {
    var header: some View {
        ReorderingSessionHeader(session: session)
    }
    
    private var measurements: some View {
        _ABMeasurementsView(measurementsViewModel: DefaultSyncingMeasurementsViewModel(measurementStreamStorage: measurementStreamStorage,
                                                                                       sessionDownloader: SessionDownloadService(client:URLSession.shared,
                                                                                                                                 authorization: UserAuthenticationSession(),
                                                                                                                                 responseValidator: DefaultHTTPResponseValidator(),
                                                                                                                                 urlProvider: urlProvider),
                                                                                       session: session),
                            session: session,
                            isCollapsed: $isCollapsed,
                            selectedStream: $selectedStream,
                            thresholds: thresholds,
                            measurementPresentationStyle: shouldShowValues)
    }
    
    func descriptionText(stream: MeasurementStreamEntity) -> some View {
        return Text("\(stream.session.isMobile ? Strings.SessionCartView.avgSessionMin : Strings.SessionCartView.avgSessionH) \(stream.unitSymbol ?? "")")
    }
    
    
    
}
