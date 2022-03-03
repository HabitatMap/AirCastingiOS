// Created by Lunar on 16/02/2022.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine
import FirebaseRemoteConfig
import Resolver

class SearchMapViewModel: ObservableObject {
    var passedLocation: String
    var passedLocationAddress: CLLocationCoordinate2D
    var passedParameter: String
    @Injected private var mapSessionsDownloader: MapSessionsDownloader
    @Published var sessionsList = [MappedSession]()
    @Published var showRedoButton: Bool = false
    @Published var showLoadingIndicator: Bool = false
    @Published var alert: AlertInfo?
    @Published var shouldDismissView: Bool = false
    private var currentPosition: GeoSquare?
    
    init(passedLocation: String, passedLocationAddress: CLLocationCoordinate2D, passedParameter: String) {
        self.passedLocation = passedLocation
        self.passedLocationAddress = passedLocationAddress
        self.passedParameter = passedParameter
    }
    
    func redoTapped() {
        guard let currentPosition = currentPosition else {
            Log.warning("Should never happen that current position is not present")
            return
        }
        updateSessionList(geoSquare: currentPosition)
        showRedoButton = false
    }
    
    func mapPositionsChanged(geoSquare: GeoSquare) {
        if currentPosition == nil {
          updateSessionList(geoSquare: geoSquare)
        } else {
            showRedoButton = true
        }
      currentPosition = geoSquare
    }
    
    private func updateSessionList(geoSquare: GeoSquare) {
        showLoadingIndicator = true
        mapSessionsDownloader.getSessions(geoSquare: geoSquare) { result in
            DispatchQueue.main.async { self.showLoadingIndicator = false }
            switch result {
            case .success(let sessions):
                DispatchQueue.main.async {
                    self.sessionsList = sessions.map { s in
                        return MappedSession(id: s.id,
                                      location: .init(latitude: s.latitude, longitude: s.longitude),
                                      markerImage: UIImage(systemName: "circle.circle.fill")!)
                        
                    }
                }
            case .failure(let error):
                Log.warning("Error when downloading sessions \(error)")
                DispatchQueue.main.async {
                    self.alert = InAppAlerts.downloadingSessionsFailedAlert {
                        self.shouldDismissView = true
                    }
                }
            }
        }
    }
}
