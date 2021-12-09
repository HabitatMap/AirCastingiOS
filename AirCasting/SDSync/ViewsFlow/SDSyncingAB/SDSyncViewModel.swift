// Created by Lunar on 21/07/2021.
//

import Combine
import CoreBluetooth

struct SDSyncProgressViewModel {
    let title: String
    let current: String
    let total: String

    func progressLabel() -> String {
        "Syncing " + title + ": " + "\(current)/\(total)"
    }
}

protocol SDSyncViewModel: ObservableObject {
    var shouldDismiss: Published<Bool>.Publisher { get }
    var isSyncCompleted: Published<Bool>.Publisher { get }
    var presentNextScreen: Bool { get set }
    var presentFailedSyncAlert: Bool { get set }
    var progress: Published<SDSyncProgressViewModel?>.Publisher { get }
    func connectToAirBeamAndSync()
}

class SDSyncViewModelDefault: SDSyncViewModel, ObservableObject {

    var shouldDismiss: Published<Bool>.Publisher { $shouldDismissValue }
    var isSyncCompleted: Published<Bool>.Publisher { $isSyncCompletedValue }
    var progress: Published<SDSyncProgressViewModel?>.Publisher { $progressValue }

    @Published private var shouldDismissValue: Bool = false
    @Published private var isSyncCompletedValue: Bool = false
    @Published private var progressValue: SDSyncProgressViewModel?
    @Published var presentNextScreen: Bool = false
    @Published var presentFailedSyncAlert: Bool = false
    
    private let peripheral: CBPeripheral
    private let airBeamConnectionController: AirBeamConnectionController
    private let sdSyncController: SDSyncController
    private let userAuthenticationSession: UserAuthenticationSession
    private let sessionContext: CreateSessionContext

    init(airBeamConnectionController: AirBeamConnectionController,
         sdSyncController: SDSyncController,
         userAuthenticationSession: UserAuthenticationSession,
         sessionContext: CreateSessionContext,
         peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.airBeamConnectionController = airBeamConnectionController
        self.sdSyncController = sdSyncController
        self.userAuthenticationSession = userAuthenticationSession
        self.sessionContext = sessionContext
    }

    func connectToAirBeamAndSync() {
        self.airBeamConnectionController.connectToAirBeam(peripheral: peripheral) { success in
            guard success else {
                DispatchQueue.main.async {
                    self.isSyncCompletedValue = success
                    self.shouldDismissValue = !success
                }
                return
            }
            self.configureABforSync()
            self.sdSyncController.syncFromAirbeam(self.peripheral, progress: { [weak self] newProgress in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    let sessionType = self.stringForSessionType(newProgress.sessionType)
                    self.progressValue = .init(title: sessionType, current: String(newProgress.progress.received), total: String(newProgress.progress.expected))
                }
            }, completion: { [weak self] result in
                //TODO: SD card should be cleared only if the files are not corrupted
                guard let self = self else { return }
                result ? self.clearSDCard() : nil
                self.disconnectAirBeam()
                DispatchQueue.main.async {
                    self.isSyncCompletedValue = result
                    self.presentNextScreen = result
                    self.shouldDismissValue = !result
                    self.presentFailedSyncAlert = !result
                }
            })
        }
    }

    private func configureABforSync() {
        let configurator = AirBeam3Configurator(userAuthenticationSession: self.userAuthenticationSession,
                                                peripheral: self.peripheral)
        configurator.configureSDSync()
    }

    private func clearSDCard() {
        let configurator = AirBeam3Configurator(userAuthenticationSession: self.userAuthenticationSession,
                                                peripheral: self.peripheral)
        configurator.clearSDCard()
    }

    private func disconnectAirBeam() {
        airBeamConnectionController.disconnectAirBeam(peripheral: peripheral)
    }

    private func stringForSessionType(_ sessionType: SDCardSessionType) -> String {
        //TODO: Correct string value and move to strings
        switch sessionType {
        case .cellular: return "Cellular"
        case .fixed: return "Fixed"
        case .mobile: return "Mobile"
        }
    }
}
