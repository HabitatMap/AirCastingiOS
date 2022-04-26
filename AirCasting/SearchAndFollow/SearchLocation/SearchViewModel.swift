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
    @Published private var parameter: MapDownloaderMeasurementType = .ozone
    @Published private var sensor: MapDownloaderSensorType = .OzoneSensor
    
    var continueDisabled: Bool { addressName == "" }
    var shoudShowPMChoiceSheet: Bool { parameter == .particulateMatter }
    var getParameter: MapDownloaderMeasurementType { parameter }
    var getSensor: MapDownloaderSensorType { sensor }
    func textFieldTapped() { isLocationPopupPresented.toggle() }
    
    func onPMSensorTap(with sensor: PMSensorType) {
        self.sensor = MapDownloaderSensorType.allCases.first(where: { $0.capitalizedName == sensor.capitalizedName }) ?? .AB3and2
    }
    
    func onOzoneSensorTap(with sensor: OzoneSensorType) {
        self.sensor = MapDownloaderSensorType.allCases.first(where: { $0.capitalizedName == sensor.capitalizedName }) ?? .OzoneSensor 
    }
    
    func onParameterTap(with param: ParameterType) {
        self.parameter = MapDownloaderMeasurementType.allCases.first(where: { $0.capitalizedName == param.capitalizedName }) ?? .particulateMatter
        self.parameter == .particulateMatter ? (sensor = .AB3and2) : (sensor = .OzoneSensor)
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
