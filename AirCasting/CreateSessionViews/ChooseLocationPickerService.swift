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

class BindableLocationTracker: UserTracker, ObservableObject {
    var locationSource: CLLocationCoordinate2D {
        didSet {
            guard oldValue != locationSource else { return }
            newPosClosure?(.init(latitude: locationSource.latitude,
                                 longitude: locationSource.longitude))
            objectWillChange.send()
        }
    }
    
    private var newPosClosure: ((CLLocation) -> Void)?
    
    init() {
        let locationTracker = Resolver.resolve(LocationTracker.self)
        locationSource = locationTracker.location.value?.coordinate ?? .init(latitude: 0, longitude: 0)
    }
    
    func startTrackingUserPosision(_ newPos: @escaping (CLLocation) -> Void) {
        self.newPosClosure = newPos
        newPos(.init(latitude: locationSource.latitude,
                     longitude: locationSource.longitude))
    }
}
