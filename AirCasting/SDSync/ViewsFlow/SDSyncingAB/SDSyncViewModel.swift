// Created by Lunar on 21/07/2021.
//

import Foundation
import Combine
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

    private let device: NewBluetoothManager.BluetoothDevice
    @Injected private var airBeamConnectionController: AirBeamConnectionController
    @Injected private var sdSyncController: SDSyncController
    private let sessionContext: CreateSessionContext

    init(sessionContext: CreateSessionContext,
         device: NewBluetoothManager.BluetoothDevice) {
        self.device = device
        self.sessionContext = sessionContext
    }

    func connectToAirBeamAndSync() {
        self.airBeamConnectionController.connectToAirBeam(device: device) { result in
            Log.info("[SD SYNC] Completed connecting to AB")
            guard result == .success else {
                DispatchQueue.main.async {
                    self.presentNextScreen = false
                    self.getConnectionAlert(result)
                }
                return
            }
            self.sdSyncController.syncFromAirbeam(self.device, progress: { [weak self] newStatus in
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
                    // TODO: move this check to new bluetooth manager
                    guard self.device.peripheral.state == .connected else {
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
        self.sdSyncController.clearSDCard(self.device) { result in
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
        airBeamConnectionController.connectToAirBeam(device: device) { [weak self] result in
            guard let self = self else { return }
            guard result == .success else {
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
        airBeamConnectionController.disconnectAirBeam(device: device)
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
    
    private func getConnectionAlert(_ result: AirBeamServicesConnectionResult) {
        switch result {
        case .timeout:
            self.alert = InAppAlerts.connectionTimeoutAlert {
                self.shouldDismiss = true
            }
        case .deviceBusy:
            self.alert = InAppAlerts.bluetoothSessionAlreadyRecordingAlert {
                self.shouldDismiss = true
            }
        case .success:
            break
        case .incompatibleDevice:
            self.alert = InAppAlerts.incompatibleDevice {
                self.shouldDismiss = true
            }
        case .unknown(_):
            self.alert = InAppAlerts.genericErrorAlert {
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
