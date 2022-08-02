// Created by Lunar on 01/08/2022.
//
import SwiftUI
import GoogleMaps

class CustomLocationButler: ObservableObject {
    private let coreMap: GoogleMapCore
    @Binding private var placePickerLocation: CLLocationCoordinate2D?
    
    init(placePickerLocation: Binding<CLLocationCoordinate2D?>) {
        self._placePickerLocation = placePickerLocation
        self.coreMap = GoogleMapCoreDefault()
    }
    
    var cameraUpdate: GMSCameraUpdate {
        let location = placePickerLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        return GMSCameraUpdate.setTarget(location)
    }
    
    func initialMakeUIVIew() -> GMSMapView {
        coreMap.initialCommonMakeUIView()
    }
    
    func optionalTrackerLocation() -> (Double, Double) {
        coreMap.optionalTrackerLocation()
    }
}
