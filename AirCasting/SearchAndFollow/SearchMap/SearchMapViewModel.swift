// Created by Lunar on 16/02/2022.
//

import Foundation
import CoreLocation
import SwiftUI
import Resolver

enum PointerValue: Equatable {
    case value(of: Int)
    case noValue
    
    var number: Int {
        switch self {
        case .noValue: return -1
        case .value(of: let value):
            return value
        }
    }
}

class SearchMapViewModel: ObservableObject {
    var passedLocation: String
    @Published var passedLocationAddress: CLLocationCoordinate2D
    private let measurementType: MapDownloaderMeasurementType
    private let sensorType: MapDownloaderSensorType
    @Injected private var mapSessionsDownloader: SessionsForLocationDownloader
    @Published var isLocationPopupPresented = false
    @Published var sessionsList = [MapSessionMarker]()
    @Published var searchAgainButton: Bool = false
    @Published var showLoadingIndicator: Bool = false
    @Published var alert: AlertInfo?
    @Published var shouldDismissView: Bool = false
    @Published var cardPointerID: PointerValue = .noValue
    @Published var shouldCardsScroll: Bool = false
    private var currentPosition: GeoSquare?
    
    init(passedLocation: String, passedLocationAddress: CLLocationCoordinate2D, measurementType: MapDownloaderMeasurementType, sensorType: MapDownloaderSensorType) {
        self.passedLocation = passedLocation
        self.passedLocationAddress = passedLocationAddress
        self.measurementType = measurementType
        self.sensorType = sensorType
    }
    
    func textFieldTapped() { isLocationPopupPresented.toggle() }
    func getMeasurementName() -> String { measurementType.capitalizedName }
    func getSensorName() -> String { sensorType.capitalizedName }
    
    func strokeColor(sessionID: Int) -> Color {
        cardPointerID.number == sessionID ? Color.accentColor : .clear
    }
    
    func enteredNewLocation(name newLocationName: String) {
        passedLocation = newLocationName
    }
    
    func enteredNewLocationAdress(_ newLocationAddress: CLLocationCoordinate2D) {
        passedLocationAddress = newLocationAddress
    }
    
    func dismissedTapped() {
        guard let currentPosition = currentPosition else {
            Log.warning("Should never happen that current position is not present")
            return
        }
        updateSessionList(geoSquare: currentPosition)
        searchAgainButton = false
        cardPointerID = .noValue
    }
    
    func redoTapped() {
        guard let currentPosition = currentPosition else {
            Log.warning("Should never happen that current position is not present")
            return
        }
        updateSessionList(geoSquare: currentPosition)
        searchAgainButton = false
        cardPointerID = .noValue
    }
    
    func mapPositionsChanged(geoSquare: GeoSquare) {
        if currentPosition == nil {
            updateSessionList(geoSquare: geoSquare)
        } else {
            searchAgainButton = true
        }
        currentPosition = geoSquare
    }
    
    func startingLocationChanged(geoSquare: GeoSquare) {
        updateSessionList(geoSquare: geoSquare)
        searchAgainButton = false
        cardPointerID = .noValue
    }
    
    func markerSelectionChanged(using point: Int) {
        self.cardPointerID = .value(of: point)
        shouldCardsScroll.toggle()
    }
    
    private func updateSessionList(geoSquare: GeoSquare) {
        showLoadingIndicator = true
        
        // We are going to use current day and current day year ago
        let timeFrom = DateBuilder.getRawDate().yearAgo.beginingOfDayInSeconds
        let timeTo = DateBuilder.getRawDate().endOfDayInSeconds
        
        mapSessionsDownloader.getSessions(geoSquare: geoSquare,
                                          timeFrom: timeFrom,
                                          timeTo: timeTo,
                                          parameter: measurementType,
                                          sensor: sensorType) { result in
            DispatchQueue.main.async { self.showLoadingIndicator = false }
            switch result {
            case .success(let sessions):
                self.handleUpdatingSuccess(using: sessions)
            case .failure(let error):
                self.handleUpdatingError(using: error)
            }
        }
    }
    
    private func handleUpdatingSuccess(using sessions: [MapDownloaderSearchedSession]) {
        DispatchQueue.main.async {
            self.sessionsList = sessions.compactMap { s in
                guard let stream = s.streams.first?.value else {
                    // If session doesn't have any streams we don't want to display it on the map
                    return nil
                }
                return MapSessionMarker(id: s.id,
                                        username: s.username,
                                        uuid: s.uuid,
                                        title: s.title,
                                        location: .init(latitude: s.latitude, longitude: s.longitude),
                                        startTime: s.startTimeLocal,
                                        endTime: s.endTimeLocal,
                                        markerImage: UIImage(systemName: "circle.circle.fill")!,
                                        streamId: stream.id,
                                        thresholdsValues: ThresholdsValue(veryLow: Int32(stream.thresholdVeryLow), low: Int32(stream.thresholdLow), medium: Int32(stream.thresholdMedium), high: Int32(stream.thresholdHigh), veryHigh: Int32(stream.thresholdVeryHigh)))
            }
        }
    }
    
    private func handleUpdatingError(using error: Error) {
        Log.warning("Error when downloading sessions \(error)")
        DispatchQueue.main.async {
            self.alert = InAppAlerts.downloadingSessionsFailedAlert {
                self.shouldDismissView = true
            }
        }
    }
}
