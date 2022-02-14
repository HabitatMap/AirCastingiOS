// Created by Lunar on 14/02/2022.
//
import Foundation
import GooglePlaces
import SwiftUI

class SearchPickerService: PlacePickerService {
    @Binding var address: String
    
    init(address: Binding<String>) {
        self._address = address
    }
    
    func didComplete(using place: GMSPlace) {
        address = place.name ?? ""
    }
}
