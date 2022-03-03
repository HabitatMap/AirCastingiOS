// Created by Lunar on 14/02/2022.
//

import Foundation
import CoreLocation

class SearchViewModel: ObservableObject {
    
    @Published var isLocationPopupPresented = false
    @Published var addressName = ""
    @Published var addresslocation = CLLocationCoordinate2D(latitude: 20.0, longitude: 20.0)
    
    func textFieldTapped() { isLocationPopupPresented.toggle() }
    
    func updateLocationName(using newLocationName: String) {
        addressName = newLocationName
    }
    
    func updateLocationAddress(using newLocationAddress: CLLocationCoordinate2D) {
        addresslocation = newLocationAddress
    }
}
