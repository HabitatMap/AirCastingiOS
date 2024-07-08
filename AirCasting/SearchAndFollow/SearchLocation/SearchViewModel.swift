// Created by Lunar on 14/02/2022.
//

import Foundation
import CoreLocation
import Resolver

/// PM will stand for "Particulate matter"

class SearchViewModel: ObservableObject {
    @Injected private var networkChecker: NetworkChecker
    
    @Published var isLocationPopupPresented = false
    @Published var addressName = ""
    @Published var addresslocation = CLLocationCoordinate2D(latitude: 20.0, longitude: 20.0)
    @Published var alert: AlertInfo?
    @Published var measurementTypes = [SearchParameter]()
    @Published var sensorTypes = [SearchParameter]()
    
    var continueDisabled: Bool { addressName == "" }
    
    var selectedParameter: MeasurementType? {
        guard let selected = measurementTypes.first(where: { $0.isSelected }) else { return nil }
        return measurementType(from: selected.name)
    }
    
    var selectedSensor: SensorType? {
        guard let selected = sensorTypes.first(where: { $0.isSelected }) else { return nil }
        return sensorType(from: selected.name)
    }
    
    init() {
        measurementTypes = [
            .init(isSelected: true, name: Strings.SearchFollowParamNames.particulateMatter),
            .init(isSelected: false, name: Strings.SearchFollowParamNames.ozone),
            .init(isSelected: false, name: Strings.SearchFollowParamNames.nitrogenDioxide),
        ]
        onParameterTap(with: Strings.SearchFollowParamNames.particulateMatter)
    }
    
    func textFieldTapped() { isLocationPopupPresented.toggle() }
    
    func onParameterTap(with param: String) {
        deselectAll(measurementTypes)
        self.measurementTypes.first(where: { $0.name == param })?.isSelected = true
        
        switch measurementType(from: param) {
        case .particulateMatter: self.sensorTypes = [
            .init(isSelected: true, name: SensorType.AirBeam.capitalizedName),
            .init(isSelected: false, name: SensorType.Govt.capitalizedName),
        ]
            
        case .ozone: self.sensorTypes = [
            .init(isSelected: true, name: SensorType.Govt.capitalizedName)
        ]
            
        case .nitrogenDioxide: self.sensorTypes = [
            .init(isSelected: true, name: SensorType.Govt.capitalizedName)
        ]
        case .none: return
        }
        self.objectWillChange.send()
    }
    
    func onSensorTap(with name: String) {
        deselectAll(sensorTypes)
        self.sensorTypes.first(where: { $0.name == name })?.isSelected = true
        self.objectWillChange.send()
    }
    
    func locationNameInteracted(with newLocationName: String) {
        addressName = newLocationName
    }
    
    func locationAddressInteracted(with newLocationAddress: CLLocationCoordinate2D) {
        addresslocation = newLocationAddress
    }
    
    func viewInitialized(onEnd: @escaping () -> Void) {
        if !networkChecker.connectionAvailable {
            (alert = InAppAlerts.noNetworkAlert(dismiss: {
                onEnd()
            }))
        }
    }
    
    private func deselectAll(_ all: [SearchParameter]) {
        all.forEach({ $0.isSelected = false })
    }
    
    private func measurementType(from: String) -> MeasurementType? {
        switch from {
        case Strings.SearchFollowParamNames.particulateMatter: return .particulateMatter
        case Strings.SearchFollowParamNames.ozone: return .ozone
        case Strings.SearchFollowParamNames.nitrogenDioxide: return .nitrogenDioxide
        default: return nil
        }
    }
    
    private func sensorType(from: String) -> SensorType? {
        switch from {
        case Strings.SearchFollowSensorNames.AirBeam3and2: return .AirBeam
        case Strings.SearchFollowSensorNames.Govt: return .Govt
        default: return nil
        }
    }
}
