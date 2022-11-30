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

class BindableLocationTracker: MapLocationTracker, ObservableObject {
    func getLastKnownLocation() -> CLLocation? {
        
        CLLocation(latitude: locationSource.latitude,
                   longitude: locationSource.longitude)
    }
    
    var locationSource: CLLocationCoordinate2D {
        didSet {
            guard oldValue != locationSource else { return }
            newPositionClosure?(.init(latitude: locationSource.latitude,
                                 longitude: locationSource.longitude))
            objectWillChange.send()
        }
    }
    
    private var newPositionClosure: ((CLLocation) -> Void)?
    
    init() {
        let locationTracker = Resolver.resolve(LocationTracker.self)
        locationSource = locationTracker.location.value?.coordinate ?? .init(latitude: 0, longitude: 0)
    }
    
    func startTrackingUserPosition(_ newPos: @escaping (CLLocation) -> Void) {
        self.newPositionClosure = newPos
        newPos(.init(latitude: locationSource.latitude,
                     longitude: locationSource.longitude))
    }
}
