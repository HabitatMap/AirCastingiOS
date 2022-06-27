// Created by Lunar on 14/02/2022.
//
import Foundation
import GooglePlaces
import Resolver
import SwiftUI

class ChooseLocationPickerService: PlacePickerService {
    @Binding private var address: String
    @Binding var location: CLLocationCoordinate2D?
    
    init(address: Binding<String>, location: Binding<CLLocationCoordinate2D?>) {
        self._address = .init(projectedValue: address)
        self._location = .init(projectedValue: location)
    }
    
    func didComplete(using place: GMSPlace) {
        address = place.formattedAddress ?? ""
        location = place.coordinate
    }
}
