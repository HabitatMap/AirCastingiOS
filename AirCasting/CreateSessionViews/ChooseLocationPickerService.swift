// Created by Lunar on 14/02/2022.
//
import Foundation
import GooglePlaces
import Resolver
import SwiftUI

class ChooseLocationPickerService: PlacePickerService {
    @InjectedObject private var tracker: LocationTracker
    @Binding var address: String
    
    init(address: Binding<String>) {
        self._address = address
    }
    
    func didComplete(using place: GMSPlace) {
        address =  place.name ?? ""
        tracker.googleLocation = [PathPoint(location: place.coordinate, measurementTime: DateBuilder.getFakeUTCDate())]
    }
}
