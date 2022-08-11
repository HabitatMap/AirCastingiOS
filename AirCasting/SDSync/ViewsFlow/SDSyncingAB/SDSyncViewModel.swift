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
    var shouldDismiss: Bool { get set }
    var alert: AlertInfo? { get set }
    var progress: Published<SDSyncProgressViewModel?>.Publisher { get }
    func connectToAirBeamAndSync()
}

// [RESOLVER] Move this VM init to view afte all dependencies are resolved
class SDSyncViewModelDefault: SDSyncViewModel, ObservableObject {
    var progress: Published<SDSyncProgressViewModel?>.Publisher { $progressValue }

    @Published private var progressValue: SDSyncProgressViewModel?
    @Published var isDownloadingFinished: Bool = false
    @Published var presentNextScreen: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var alert: AlertInfo?

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
            Log.info("[SD SYNC] Completed connecting to AB")
            guard success else {
                DispatchQueue.main.async {
                    self.presentNextScreen = success
                    self.alert = InAppAlerts.connectionTimeoutAlert {
                        self.shouldDismiss = true
                    }
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
                Log.info("[SD SYNC] Completed syncing with result: \(result)")
                guard let self = self else { return }
                switch result {
                case .success():
                    guard self.peripheral.state == .connected else {
                        Log.info("[SD SYNC] Device disconnected. Attempting reconnect")
                        self.reconnectWithAirbeamAndClearCard()
                        return
                    }
                    self.clearSDCard()
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.alert = self.alertForError(error)
                        self.presentNextScreen = false
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
                    Log.error("[SD SYNC] Couldn't clear SD card after sync")
                }
            }
            self.disconnectAirBeam()
        }
    }
    
    private func reconnectWithAirbeamAndClearCard() {
        airBeamConnectionController.connectToAirBeam(peripheral: peripheral) { [weak self] success in
            guard let self = self else { return }
            guard success else {
                Log.info("[SD SYNC] Reconnecting failed")
                DispatchQueue.main.async {
                    self.presentNextScreen = false
                    self.alert = InAppAlerts.failedSDClearingAlert {
                        self.shouldDismiss = true
                    }
                }
                return
            }
            self.clearSDCard()
        }
    }

    private func disconnectAirBeam() {
        airBeamConnectionController.disconnectAirBeam(peripheral: peripheral)
    }
    
    private func alertForError(_ error: SDSyncError) -> AlertInfo {
        switch error {
        case .unidetifiableDevice:
            return InAppAlerts.connectionTimeoutAlert {
                self.shouldDismiss = true
            }
        case .filesCorrupted:
            return InAppAlerts.sdSyncFilesCorruptedAlert {
                self.shouldDismiss = true
            }
        case .readingDataFailure:
            return InAppAlerts.sdSyncReadingDataAlert {
                self.shouldDismiss = true
            }
        case .fixedSessionsProcessingFailure:
            return InAppAlerts.sdSyncFixedFailAlert {
                self.shouldDismiss = true
            }
        case .mobileSessionsProcessingFailure:
            return InAppAlerts.sdSyncMobileFailAlert {
                self.shouldDismiss = true
            }
        }
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
