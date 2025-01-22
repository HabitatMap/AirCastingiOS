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
    @Published var passedLocationAddress: CLLocationCoordinate2D {
        didSet {
            Log.info("MARTA: passedLocationAddress changed")
        }
    }
    private let measurementType: MeasurementType
    private let sensorType: SensorType
    @Injected private var mapSessionsDownloader: SessionsForLocationDownloader {
        didSet {
            Log.info("MARTA: mapSessionsDownloader changed")
        }
    }
    @Published var isLocationPopupPresented = false {
        didSet {
            Log.info("MARTA: isLocationPopupPresented changed")
        }
    }
    @Published var sessionsList = [MapSessionMarker]() {
        didSet {
            Log.info("MARTA: sessionsList changed")
        }
    }
    @Published var searchAgainButton: Bool = false {
        didSet {
            Log.info("MARTA: searchAgainButton changed")
        }
    }
    @Published var showLoadingIndicator: Bool = false {
        didSet {
            Log.info("MARTA: showLoadingIndicator changed")
        }
    }
    @Published var alert: AlertInfo? {
        didSet {
            Log.info("MARTA: alert changed")
        }
    }
    @Published var shouldDismissView: Bool = false {
        didSet {
            Log.info("MARTA: shouldDismissView changed")
        }
    }
    @Published var cardPointerID: PointerValue = .noValue {
        didSet {
            Log.info("MARTA: cardPointerID changed")
        }
    }
    @Published var shouldCardsScroll: Bool = false {
        didSet {
            Log.info("MARTA: shouldCardsScroll changed")
        }
    }
    private var currentPosition: GeoSquare?

    init(passedLocation: String, passedLocationAddress: CLLocationCoordinate2D, measurementType: MeasurementType, sensorType: SensorType) {
        self.passedLocation = passedLocation
        self.passedLocationAddress = passedLocationAddress
        self.measurementType = measurementType
        self.sensorType = sensorType
    }
    
    func textFieldTapped() { isLocationPopupPresented.toggle() }
    func getMeasurementName() -> String { measurementType.capitalizedName }
    func getSensorName() -> String { sensorType.capitalizedName }
    
    func strokeColor(with sessionID: Int) -> Color {
        cardPointerID.number == sessionID ? Color.accentColor : .clear
    }
    
    func enteredNewLocation(name newLocationName: String) {
        passedLocation = newLocationName
    }
    
    func enteredNewLocationAdress(_ newLocationAddress: CLLocationCoordinate2D) {
        passedLocationAddress = newLocationAddress
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
        currentPosition = geoSquare
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
                                          measurementType: measurementType.downloaderType,
                                          sensor: sensorType.downloaderType) { result in
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
        // This function causes event loop
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.sessionsList = sessions.compactMap { s in
                guard !s.streams.isEmpty else {
                    // If session doesn't have any streams we don't want to display it on the map
                    return nil
                }
                return MapSessionMarker(id: s.id,
                                        location: .init(latitude: s.latitude, longitude: s.longitude),
                                        markerImage: UIImage(systemName: "circle.circle.fill")!,
                                        session: .init(id: s.id,
                                                       uuid: s.uuid,
                                                       provider: s.username,
                                                       name: s.title,
                                                       startTime: self.timeAsDate(s.startTimeLocal),
                                                       endTime: self.timeAsDate(s.endTimeLocal),
                                                       longitude: s.longitude,
                                                       latitude: s.latitude)
                )
            }
        }
    }
    
    private func timeAsDate(_ time: String) -> Date {
        let formatter = DateFormatters.SearchAndFollow.timeFormatter
        let date = formatter.date(from: time)
        guard let d = date else {
            Log.error("Failed to convert start time received from API to date")
            return DateBuilder.getFakeUTCDate()
        }
        return d
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

extension MeasurementType {
    var downloaderType: MapDownloaderMeasurementType {
        switch self {
        case .particulateMatter: return .particulateMatter
        case .ozone: return .ozone
        case .nitrogenDioxide: return .nitrogenDioxide
        }
    }
}

extension SensorType {
    var downloaderType: MapDownloaderSensorType {
        switch self {
        case .AirBeam: return .AirBeam
        case .Govt: return .Govt
        }
    }
}
