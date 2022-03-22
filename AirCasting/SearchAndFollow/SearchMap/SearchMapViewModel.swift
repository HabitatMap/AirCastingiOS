// Created by Lunar on 16/02/2022.
//

import Foundation
import CoreLocation
import SwiftUI
import Resolver

class SearchMapViewModel: ObservableObject {
    let passedLocation: String
    let passedLocationAddress: CLLocationCoordinate2D
    let measurementType: String
    @Injected private var mapSessionsDownloader: SessionsForLocationDownloader
    @Published var sessionsList = [MapSessionMarker]()
    @Published var searchAgainButton: Bool = false
    @Published var showLoadingIndicator: Bool = false
    @Published var alert: AlertInfo?
    @Published var shouldDismissView: Bool = false
    private var currentPosition: GeoSquare?
    
    init(passedLocation: String, passedLocationAddress: CLLocationCoordinate2D, measurementType: String) {
        self.passedLocation = passedLocation
        self.passedLocationAddress = passedLocationAddress
        self.measurementType = measurementType
    }
    
    func redoTapped() {
        guard let currentPosition = currentPosition else {
            Log.warning("Should never happen that current position is not present")
            return
        }
        updateSessionList(geoSquare: currentPosition)
        searchAgainButton = false
    }
    
    func mapPositionsChanged(geoSquare: GeoSquare) {
        if currentPosition == nil {
            updateSessionList(geoSquare: geoSquare)
        } else {
            searchAgainButton = true
        }
        currentPosition = geoSquare
    }
    
    private func updateSessionList(geoSquare: GeoSquare) {
        showLoadingIndicator = true
        
        // We are going to use current day and current day year ago
        let timeFrom = DateBuilder.beginingOfDayInSeconds(using: DateBuilder().yearAgo())
        let timeTo = DateBuilder.endOfDayInSeconds(using: DateBuilder.getRawDate())
        
        mapSessionsDownloader.getSessions(geoSquare: geoSquare, timeFrom: timeFrom, timeTo: timeTo) { result in
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
            self.sessionsList = sessions.map { s in
                return MapSessionMarker(id: s.id,
                              location: .init(latitude: s.latitude, longitude: s.longitude),
                              markerImage: UIImage(systemName: "circle.circle.fill")!)
                
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
