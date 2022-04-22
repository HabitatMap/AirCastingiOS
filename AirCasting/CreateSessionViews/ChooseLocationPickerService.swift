// Created by Lunar on 14/02/2022.
//
import Foundation
import GooglePlaces
import Resolver
import SwiftUI

class ChooseLocationPickerService: PlacePickerService {
    @Injected private var tracker: LocationTracker
    @Binding private var address: String
    
    init(address: Binding<String>) {
        self._address = .init(projectedValue: address)
    }
    
    func didComplete(using place: GMSPlace) {
        address = place.formattedAddress ?? ""
        tracker.googleLocation = [PathPoint(location: place.coordinate, measurementTime: DateBuilder.getFakeUTCDate())]
    }
}
