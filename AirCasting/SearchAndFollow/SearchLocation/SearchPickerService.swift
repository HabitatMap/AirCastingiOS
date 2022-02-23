// Created by Lunar on 14/02/2022.
//
import Foundation
import GooglePlaces
import SwiftUI

class SearchPickerService: PlacePickerService {
    @Binding private var address: String
    
    init(address: Binding<String>) {
        self._address = .init(projectedValue: address)
    }
    
    func didComplete(using place: GMSPlace) {
        address = place.name ?? ""
    }
}
