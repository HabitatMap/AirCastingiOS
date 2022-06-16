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
    @Published var isSessionFollowed: Bool = false
    @Published var alert: AlertInfo?
    @Published var followButtonEnabled: Bool = false
    @Published var followButtonText: String = Strings.CompleteSearchView.followButtonTitle
    @Published var sessionStreams: Loadable<[SessionStreamViewModel]> = .loading {
        didSet {
            followButtonEnabled = sessionStreams.isReady && !isOwnSession
        }
    }
    @Published var chartViewModel = SearchAndFollowChartViewModel()
    
    let sessionLongitude: Double
    let sessionLatitude: Double
    let sessionName: String
    let sessionStartTime: Date
    let sessionEndTime: Date
    let sensorType: String
    let exitRoute: () -> Void

    private var isOwnSession: Bool { userAuthenticationSession.user?.username == session.provider }
    private var session: PartialExternalSession
    private var externalSessionWithStreams: ExternalSessionWithStreamsAndMeasurements?
    
    @Injected private var singleSessionDownloader: SingleSessionDownloader
    @Injected private var externalSessionsStore: ExternalSessionsStore
    @Injected private var service: SearchAndFollowCompleteScreenService
    @Injected private var streamsDownloader: AirBeamMeasurementsDownloader
    @Injected private var userAuthenticationSession: UserAuthenticationSession
    
    init(session: PartialExternalSession, exitRoute: @escaping () -> Void) {
        self.session = session
        sessionLongitude = session.longitude
        sessionLatitude = session.latitude
        sessionName = session.name
        sessionStartTime = session.startTime
        sessionEndTime = session.endTime
        sensorType = session.provider
        self.exitRoute = exitRoute
        refreshCompleteButtonText()
        reloadData()
        isSessionFollowed = externalSessionsStore.doesSessionExist(uuid: session.uuid)
    }
    
    private func reloadData() {
        sessionStreams = .loading
        refresh()
    }
    
    func mapTapped() {
        isMapSelected = true
    }
    
    func chartTapped() {
        isMapSelected = false
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
    
    func followButtonPressed() {
        guard externalSessionWithStreams != nil else {
            followButtonEnabled = false
            self.showAlert()
            return
        }
        followButtonText = Strings.CompleteSearchView.followingSessionButtonTitle
        followButtonEnabled = false
        saveToDb()
    }
    
    func unfollowButtonPressed() {
        guard isSessionFollowed else {
            assertionFailure("Unfollow button pressed but this session is not in our DB")
            return
        }
        service.unfollowSession(sessionUUID: session.uuid) { result in
            switch result {
            case .success:
                Log.info("Successfully unfollowed session: \(self.session.uuid)")
                DispatchQueue.main.async {
                    self.isSessionFollowed = false
                    if self.externalSessionWithStreams != nil { self.followButtonEnabled = true }
                }
            case .failure(let error):
                Log.error("Unfollowing external session failed: \(error)")
                self.showAlert()
            }
        }
    }
    
    private func refreshCompleteButtonText() {
        guard !isOwnSession else {
            followButtonText = Strings.CompleteSearchView.ownSessionButtonTitle
            return
        }
    }
    
    private func saveToDb() {
        guard let externalSessionWithStreams = externalSessionWithStreams else {
            assertionFailure("Follow button pressed when there was no session with streams")
            return
        }
        
        service.followSession(session: externalSessionWithStreams) { [weak self] result in
            switch result {
            case .success:
                Log.info("Successfully followed session: \(externalSessionWithStreams.uuid)")
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isSessionFollowed = true
                    self.followButtonText = Strings.CompleteSearchView.followButtonTitle
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
        guard let stream = session.stream.first else { self.showAlert(); return }
        guard stream.sensorName.contains("AirBeam") else { getMeasurementsAndDisplayData(); return }
        do {
            try streamsDownloader.downloadStreams(with: session.id) { result in
                switch result {
                case .success(let downloadedStreams):
                    
                    self.session.stream = []
                    
//                    TODO: Sort those streams
                    downloadedStreams.streams.forEach { stream in
                        self.session.stream.append(PartialExternalSession.Stream(id: stream.stream_id,
                                                                                 unitName: stream.unit_name,
                                                                                 unitSymbol: stream.sensor_unit,
                                                                                 measurementShortType: stream.measurement_short_type,
                                                                                 measurementType: stream.measurement_type,
                                                                                 sensorName: stream.sensor_name,
                                                                                 sensorPackageName: stream.sensor_name,
                                                                                 thresholdsValues: .init(veryLow: stream.threshold_very_low,
                                                                                                         low: stream.threshold_low,
                                                                                                         medium: stream.threshold_medium,
                                                                                                         high: stream.threshold_high,
                                                                                                         veryHigh: stream.threshold_very_high)))
                    }
                    self.session.stream.sorted(by: <#T##(PartialExternalSession.Stream, PartialExternalSession.Stream) throws -> Bool#>)
                    Log.info("Completed downloading missing streams.")
                    self.getMeasurementsAndDisplayData()
                case .failure(let error):
                    Log.error("Something went wrong when downloading missing streams. \(error.localizedDescription)")
                    self.showAlert()
                }
            }
        } catch {
            Log.error("Something went wrong when downloading missing streams. \(error.localizedDescription)")
            self.showAlert()
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
        guard let separatedSensorName = self.componentsSeparation(name: stream.sensorName) else {
            Log.error("No sensor name can be extracted from current stream.sensorName")
            return
        }
        (self.chartStartTime, self.chartEndTime) = self.chartViewModel.generateEntries(with: stream.measurements.map({ SearchAndFollowChartViewModel.ChartMeasurement(value: $0.value, time: $0.time) }), thresholds: stream.thresholdsValues, using: ChartMeasurementsFilterDefault(name: separatedSensorName))
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
    
    private func componentsSeparation(name: String) -> String? {
        if name.contains(":") {
            let value = name.components(separatedBy: ":").first!
            return value.components(separatedBy: CharacterSet.decimalDigits).joined()
        }
        let value = name.components(separatedBy: "-").first!
        return value.components(separatedBy: CharacterSet.decimalDigits).joined()
    }
}
