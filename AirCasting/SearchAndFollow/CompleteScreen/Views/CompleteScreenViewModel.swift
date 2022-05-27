// Created by Lunar on 22/02/2022.
//

import Foundation
import SwiftUI
import Resolver


enum CompletionScreenError: Error {
    case noStreams
}

class CompleteScreenViewModel: ObservableObject {
    
    struct SessionStreamViewModel: Identifiable {
        let id: Int
        let sensorName: String
        let sensorUnit: String
        let lastMeasurementValue: Double
        let color: Color
        let measurements: [Measurement]
        let thresholds: ThresholdsValue
        
        struct Measurement {
            let value: Double
            let time: Date
            let latitude: Double
            let longitude: Double
        }
    }
    
    @Published var selectedStream: Int?
    @Published var selectedStreamUnitSymbol: String?
    @Published var chartStartTime: Date?
    @Published var chartEndTime: Date?
    @Published var isMapSelected: Bool = true
    @Published var alert: AlertInfo?
    
    let sessionLongitude: Double
    let sessionLatitude: Double
    let sessionName: String
    let sessionStartTime: Date
    let sessionEndTime: Date
    let sensorType: String
    @Published var completeButtonEnabled: Bool = false
    @Published var completeButtonText: String = Strings.CompleteSearchView.confirmationButtonTitle
    @Published var sessionStreams: Loadable<[SessionStreamViewModel]> = .loading {
        didSet {
            completeButtonEnabled = sessionStreams.isReady && !sessionAlreadyFollowed
        }
    }
    @Published var chartViewModel = SearchAndFollowChartViewModel()
    
    let exitRoute: () -> Void
    
    private var session: PartialExternalSession
    private var externalSessionWithStreams: ExternalSessionWithStreamsAndMeasurements?
    private var sessionAlreadyFollowed: Bool {
        externalSessionsStore.doesSessionExist(uuid: session.uuid)
    }
    private var followedText = Strings.CompleteSearchView.followedSessionButtonTitle
    private var followingText = Strings.CompleteSearchView.followingSessionButtonTitle
    
    @Injected private var singleSessionDownloader: SingleSessionDownloader
    @Injected private var externalSessionsStore: ExternalSessionsStore
    @Injected private var service: SearchAndFollowCompleteScreenService
    @Injected private var streamsDownloader: AirBeamMeasurementsDownloader
    
    init(session: PartialExternalSession, exitRoute: @escaping () -> Void) {
        self.session = session
        sessionLongitude = session.longitude
        sessionLatitude = session.latitude
        sessionName = session.name
        sessionStartTime = session.startTime
        sessionEndTime = session.endTime
        sensorType = session.provider
        self.exitRoute = exitRoute
        if sessionAlreadyFollowed {
            completeButtonText = followedText
        }
        reloadData()
    }
    
    private func reloadData() {
        sessionStreams = .loading
        refresh()
    }
    
    func mapTapped() {
        isMapSelected.toggle()
    }
    
    func chartTapped() {
        isMapSelected.toggle()
    }
    
    func selectedStream(with id: Int) {
        if let stream = externalSessionWithStreams?.streams.first(where: { $0.id == id }) {
            assignValues(with: stream)
            defineChartRange(with: stream)
        }
    }
    
    func xMarkTapped() {
        exitRoute()
    }
    
    func confirmationButtonPressed() {
        guard externalSessionWithStreams != nil else {
            completeButtonEnabled = false
            self.showAlert()
            return
        }
        setButtonToFollowing()
        saveToDb()
    }
    
    private func setButtonToFollowing() {
        completeButtonEnabled = false
        completeButtonText = followingText
    }
    
    private func saveToDb() {
        guard let externalSessionWithStreams = externalSessionWithStreams else {
            assertionFailure("Confirmation button pressed when there was no session with streams")
            return
        }
        
        service.followSession(session: externalSessionWithStreams) { [weak self] result in
            switch result {
            case .success:
                Log.info("Successfully followed session: \(externalSessionWithStreams.uuid)")
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.completeButtonText = self.followedText
                }
            case .failure(let error):
                Log.error("Following external session failed: \(error)")
                self?.showAlert()
            }
        }
    }
    
    private func dismissView() {
        exitRoute()
    }
    
    private func refresh() {
        guard ((session.stream.first?.sensorName.contains("AirBeam")) != nil) else { getMeasurementsAndDisplayData(); return }
        var currentSensor = AirBeamStreamPrefix.airBeam3
        if session.stream.first!.sensorName.contains("AirBeam2") { currentSensor = .airBeam2 }
        do {
            try streamsDownloader.downloadStreams(with: session.id, for: currentSensor) { result in
                switch result {
                case .success(let downloadedStreams):
                    
                    // TODO: - FIX Thresholds, get those values from backend not from our hardcoded struct
                    #warning("🚨 FIX Thresholds 🚨")
                    let streamHardcodedData = [MeasurementStream(sensorName: .f, sensorPackageName: ""),
                                               MeasurementStream(sensorName: .pm1, sensorPackageName: ""),
                                               MeasurementStream(sensorName: .pm10, sensorPackageName: ""),
                                               MeasurementStream(sensorName: .pm2_5, sensorPackageName: ""),
                                               MeasurementStream(sensorName: .rh, sensorPackageName: "")]
                    
                    let sessionStream = downloadedStreams.map({ stream -> PartialExternalSession.Stream in
                        let streamLocalData = streamHardcodedData.first(where: { Self.getSensorName($0.sensorName ?? "") == Self.getSensorName(stream.sensorName)})
                        return PartialExternalSession.Stream(id: stream.streamId,
                                                             unitName: streamLocalData?.unitName ?? "",
                                                             unitSymbol: stream.sensorUnit,
                                                             measurementShortType: streamLocalData?.measurementShortType ?? "",
                                                             measurementType: streamLocalData?.measurementType ?? "",
                                                             sensorName: stream.sensorName,
                                                             sensorPackageName: "",
                                                             thresholdsValues: .init(veryLow: streamLocalData?.thresholdVeryLow ?? 0,
                                                                                     low: streamLocalData?.thresholdLow ?? 0,
                                                                                     medium: streamLocalData?.thresholdMedium ?? 0,
                                                                                     high: streamLocalData?.thresholdHigh ?? 0,
                                                                                     veryHigh: streamLocalData?.thresholdVeryHigh ?? 0))})
                    self.session.stream = []
                    sessionStream.forEach { self.session.stream.append($0) }
                    Log.info("Completed downloading missing streams.")
                    self.getMeasurementsAndDisplayData()
                case .failure(let error):
                    Log.error("Something went wrong when downloading missing streams. \(error.localizedDescription)")
                }
            }
        } catch {
            Log.error("Something went wrong when downloading missing streams. \(error.localizedDescription)")
        }
        return
    }
    
    private func getMeasurementsAndDisplayData() {
        let streams = session.stream.map(\.id)
        
        service.downloadMeasurements(streamsIds: streams) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                Log.error("Failed to download session: \(error)")
                self.showAlert()
            case .success(let downloadedStreamsWithMeasurements):
                guard !downloadedStreamsWithMeasurements.isEmpty else {
                    Log.error("Session has no streams")
                    self.showAlert()
                    return
                }
                
                DispatchQueue.main.async {
                    self.externalSessionWithStreams = self.service.createExternalSession(from: self.session, with: downloadedStreamsWithMeasurements)
                    
                    self.sessionStreams = .ready( self.externalSessionWithStreams!.streams.map {
                        .init(id: $0.id,
                              sensorName: Self.getSensorName($0.sensorName),
                              sensorUnit: $0.unitSymbol,
                              lastMeasurementValue: $0.measurements.last?.value ?? 0,
                              color: $0.thresholdsValues.colorFor(value: $0.measurements.last?.value ?? 0),
                              measurements: $0.measurements.map({.init(value: $0.value, time: $0.time, latitude: $0.latitude, longitude: $0.longitude)}), thresholds: $0.thresholdsValues)
                    })
                    
                    if let stream = self.externalSessionWithStreams!.streams.first {
                        self.assignValues(with: stream)
                        self.defineChartRange(with: stream)
                    }
                }
            }
        }
    }
    
    private func assignValues(with stream: ExternalSessionWithStreamsAndMeasurements.Stream) {
        self.selectedStream = stream.id
        self.selectedStreamUnitSymbol = stream.unitSymbol
    }
    
    private func defineChartRange(with stream: ExternalSessionWithStreamsAndMeasurements.Stream) {
        (self.chartStartTime, self.chartEndTime) = self.chartViewModel.generateEntries(with: stream.measurements.map({ SearchAndFollowChartViewModel.ChartMeasurement(value: $0.value, time: $0.time) }), thresholds: stream.thresholdsValues)
    }
    
    private func showAlert() {
        DispatchQueue.main.async {
            self.alert = InAppAlerts.failedSessionDownloadAlert(dismiss: self.dismissView)
        }
    }
    
    private static func getSensorName(_ streamName: String) -> String {
        streamName
            .replacingOccurrences(of: ":", with: "-")
            .drop { $0 != "-" }
            .replacingOccurrences(of: "-", with: "")
    }
}
