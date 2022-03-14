// Created by Lunar on 14/02/2022.
//

import Foundation
import CoreLocation
import Resolver

class SearchViewModel: ObservableObject {
    @Injected private var networkChecker: NetworkChecker
    
    @Published var isLocationPopupPresented = false
    @Published var addressName = ""
    @Published var addresslocation = CLLocationCoordinate2D(latitude: 20.0, longitude: 20.0)
    @Published var alert: AlertInfo?
    
    func textFieldTapped() { isLocationPopupPresented.toggle() }
    
    func updateLocationName(using newLocationName: String) {
        addressName = newLocationName
    }
    
    func updateLocationAddress(using newLocationAddress: CLLocationCoordinate2D) {
        addresslocation = newLocationAddress
    }
    
    func onAppearAction(onEnd: @escaping () -> Void) {
        if !networkChecker.connectionAvailable {
            (alert = InAppAlerts.noNetworkAlert(dismiss: {
                onEnd()
            }))
        }
    }
}
