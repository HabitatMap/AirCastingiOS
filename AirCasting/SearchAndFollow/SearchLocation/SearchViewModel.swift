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
    var isOzone: Bool { parameter == .ozone }
    var isPM: Bool { parameter == .particulateMatter }
    var isAB325: Bool { sensor == .AB325 }
    var isAB225: Bool { sensor == .AB225 }
    var isOpenAQ: Bool { sensor == .OpenAQ }
    var isOzoneSensor: Bool { sensor == .OzoneSensor }
    var getParameter: MapDownloaderMeasurementType { parameter }
    var getSensor: MapDownloaderSensorType { sensor }
    
    func textFieldTapped() { isLocationPopupPresented.toggle() }
    func onAB325ButtonTap() { sensor = .AB325 }
    func onAB225ButtonTap() { sensor = .AB225 }
    func onOpenAQButtonTap() { sensor = .OpenAQ }
    func onOzoneSensorButtonTap() { sensor = .OzoneSensor }
    
    func onOzoneButtonTap() {
        parameter = .ozone
        sensor = .OzoneSensor
    }
    
    func onPMButtonTap() {
        parameter = .particulateMatter
        sensor = .OpenAQ
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
