// Created by Lunar on 14/02/2022.
//
import Foundation
import GooglePlaces
import SwiftUI
import Resolver

class SearchPickerService: PlacePickerService {
    @InjectedObject private var tracker: LocationTracker
    @Binding private var addressName: String
    @Binding private var addressLocation: CLLocationCoordinate2D
    
    init(addressName: Binding<String>, addressLocation: Binding<CLLocationCoordinate2D>) {
        self._addressName = .init(projectedValue: addressName)
        self._addressLocation = .init(projectedValue: addressLocation)
    }
    
    func didComplete(using place: GMSPlace) {
        addressName = place.name ?? ""
        addressLocation = place.coordinate
    }
}
