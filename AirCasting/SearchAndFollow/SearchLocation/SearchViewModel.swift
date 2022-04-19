// Created by Lunar on 14/02/2022.
//

import Foundation
import CoreLocation
import Resolver

/// PM will stand for "Particulate matter"

struct SearchParameter: Identifiable {
    let id = UUID()
    let isSelected: Bool
    let name: String
}

class SearchViewModel: ObservableObject {
    @Injected private var networkChecker: NetworkChecker
    
    @Published var isLocationPopupPresented = false
    @Published var addressName = ""
    @Published var addresslocation = CLLocationCoordinate2D(latitude: 20.0, longitude: 20.0)
    @Published var alert: AlertInfo?
    @Published private var MeasurementType: MapDownloaderMeasurementType = .particulateMatter
    @Published private var sensor: MapDownloaderSensorType = .OpenAQ
    
    var MeasurementTypes: [SearchParameter] {
        MapDownloaderMeasurementType.allCases.map { value in
            SearchParameter.init(isSelected: value.capitalizedName == getSensor.capitalizedName, name: value.capitalizedName)
        }
    }
    
    var PMSensorTypes: [SearchParameter] {
        PMSensorType.allCases.map { value in
            SearchParameter.init(isSelected: value.capitalizedName == getSensor.capitalizedName, name: value.capitalizedName)
        }
    }
    
    var OzoneSensorTypes: [SearchParameter] {
        OzoneSensorType.allCases.map { value in
            SearchParameter.init(isSelected: value.capitalizedName == getSensor.capitalizedName, name: value.capitalizedName)
        }
    }
    
    var continueDisabled: Bool { addressName == "" }
    var getParameter: MapDownloaderMeasurementType { MeasurementType }
    var getSensor: MapDownloaderSensorType { sensor }
    func textFieldTapped() { isLocationPopupPresented.toggle() }
    
    func onPMSensorTap(with sensor: String) {
        self.sensor = MapDownloaderSensorType.allCases.first(where: { $0.capitalizedName == sensor }) ?? .AB3and2
    }
    
    func onOzoneSensorTap(with sensor: String) {
        self.sensor = MapDownloaderSensorType.allCases.first(where: { $0.capitalizedName == sensor }) ?? .OzoneSensor
    }
    
    func onParameterTap(with param: String) {
        self.MeasurementType = MapDownloaderMeasurementType.allCases.first(where: { $0.capitalizedName == param }) ?? .particulateMatter
        self.MeasurementType == .particulateMatter ? (sensor = .AB3and2) : (sensor = .OzoneSensor)
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
}
