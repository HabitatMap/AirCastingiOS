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
    
    private let locationTracker = Resolver.resolve(LocationTracker.self)
    private var newPositionClosure: ((CLLocation) -> Void)?
    
    var ovverridenLocation: CLLocationCoordinate2D? {
        didSet {
           callObservers()
        }
    }
    
    init() {
        locationTracker.start()
        ovverridenLocation = locationTracker.location.value?.coordinate ?? .init(latitude: 0, longitude: 0)
    }
    
    deinit {
        let locationTracker = Resolver.resolve(LocationTracker.self)
        locationTracker.stop()
    }
    
    func startTrackingUserPosition(_ newPos: @escaping (CLLocation) -> Void) -> MapLocationTrackerStoper {
        self.newPositionClosure = newPos
        callObservers()
        return Stoper()
    }
    
    func getLastKnownLocation() -> CLLocation? {
        let location = getLocation()
        return .init(latitude: location.latitude,
                     longitude: location.longitude)
    }
    
    private func callObservers() {
        let location = getLocation()
        
        newPositionClosure?(.init(latitude: location.latitude,
                                  longitude: location.longitude))
        objectWillChange.send()
    }
    
    private func getLocation() -> CLLocationCoordinate2D {
        guard let ovverridenLocation = self.ovverridenLocation else {
            return self.locationTracker.location.value?.coordinate ?? .init(latitude: 0, longitude: 0)
        }
        return ovverridenLocation
    }
    
    private struct Stoper: MapLocationTrackerStoper {
        func stopTrackingUserPosition() {
            
        }
    }
}
