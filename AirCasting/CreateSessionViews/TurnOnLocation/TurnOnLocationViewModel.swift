// Created by Lunar on 02/08/2021.
//

import Foundation
import Resolver

enum TurnOnLocationUiProcess {
    case sdClear
    case sdSync
    case createSession(sessionContext: CreateSessionContext)
}

// [RESOLVER] Init this VM inside View
class TurnOnLocationViewModel: ObservableObject {
    @Published var isPowerABLinkActive = false
    @Published var isTurnBluetoothOnLinkActive = false
    @Published var isMobileLinkActive = false
    @Published var restartABLink = false
    @Published var unplugABLink = false
    @Published var alert: AlertInfo?
    
    @Injected private var locationAuthorization: LocationAuthorization
    @Injected private var bluetoothHandler: BluetoothPermisionsChecker
    
    private let process: TurnOnLocationUiProcess
    
    init(process: TurnOnLocationUiProcess) {
        self.process = process
    }
    
    var isSDClearProcess: Bool {
        return if case .sdClear = process { true } else { false }
    }
    
    var shouldShowAlert: Bool {
        locationAuthorization.locationState == .denied
    }
    
    func requestLocationAuthorisation() {
        locationAuthorization.requestAuthorization()
    }
    
    func onButtonClick() {
        if shouldShowAlert {
            showRequestLocationAlert()
        } else {
            switch process {
            case .sdClear:
                restartABLink.toggle()
            case .sdSync:
                unplugABLink.toggle()
            case .createSession(let sessionContext):
                if sessionContext.isMobileSession {
                    isMobileLinkActive = true
                } else if bluetoothHandler.isBluetoothDenied() {
                    isTurnBluetoothOnLinkActive = true
                } else {
                    isPowerABLinkActive.toggle()
                }
            }
        }
    }
    
    private func showRequestLocationAlert() {
        alert = InAppAlerts.locationAlert()
    }
}
