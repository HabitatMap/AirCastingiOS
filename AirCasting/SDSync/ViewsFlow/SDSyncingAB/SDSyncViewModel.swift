// Created by Lunar on 21/07/2021.
//

import Combine
import CoreBluetooth
import Resolver

struct SDSyncProgressViewModel {
    let title: String
    let current: String
    let total: String
}

protocol SDSyncViewModel: ObservableObject {
    var presentNextScreen: Bool { get set }
    var isDownloadingFinished: Bool { get }
    var presentFailedSyncAlert: Bool { get set }
    var progress: Published<SDSyncProgressViewModel?>.Publisher { get }
    func connectToAirBeamAndSync()
}

// [RESOLVER] Move this VM init to view afte all dependencies are resolved
class SDSyncViewModelDefault: SDSyncViewModel, ObservableObject {

    var progress: Published<SDSyncProgressViewModel?>.Publisher { $progressValue }

    @Published private var progressValue: SDSyncProgressViewModel?
    @Published var isDownloadingFinished: Bool = false
    @Published var presentNextScreen: Bool = false
    @Published var presentFailedSyncAlert: Bool = false

    private let peripheral: CBPeripheral
    @Injected private var airBeamConnectionController: AirBeamConnectionController
    @Injected private var sdSyncController: SDSyncController
    private let sessionContext: CreateSessionContext

    init(sessionContext: CreateSessionContext,
         peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.sessionContext = sessionContext
    }

    func connectToAirBeamAndSync() {
        self.airBeamConnectionController.connectToAirBeam(peripheral: peripheral) { success in
            Log.info("## Completed connecting to AB")
            guard success else {
                DispatchQueue.main.async {
                    self.presentNextScreen = success
                    self.presentFailedSyncAlert = !success
                }
                return
            }
            self.sdSyncController.syncFromAirbeam(self.peripheral, progress: { [weak self] newStatus in
                guard let self = self else { return }
                switch newStatus {
                case .inProgress(let progress):
                    DispatchQueue.main.async {
                        let sessionType = self.stringForSessionType(progress.sessionType)
                        self.progressValue = .init(title: sessionType, current: String(progress.progress.received), total: String(progress.progress.expected))
                    }
                case .finalizing:
                    DispatchQueue.main.async {
                        self.isDownloadingFinished = true
                    }
                }
            }, completion: { [weak self] result in
                Log.info("## Completed syncing with result: \(result)")
                guard let self = self else { return }
                if result {
                    self.clearSDCard()
                } else {
                    DispatchQueue.main.async {
                        self.presentNextScreen = false
                        self.presentFailedSyncAlert = true
                    }
                    self.disconnectAirBeam()
                }
            })
        }
    }

    private func clearSDCard() {
        self.sdSyncController.clearSDCard(self.peripheral) { result in
            DispatchQueue.main.async {
                self.presentNextScreen = true
                if !result {
                    Log.error("Couldn't clear SD card after sync")
                }
            }
            self.disconnectAirBeam()
        }
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
