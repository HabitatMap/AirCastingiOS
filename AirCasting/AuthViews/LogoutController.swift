// Created by Lunar on 26/04/2022.
//

import Foundation
import Resolver
import Combine

protocol LogoutController {
    func logout(onEnd: @escaping () -> Void) throws
}

final class DefaultLogoutController: LogoutController {
    @Injected private var sessionSynchronizer: SessionSynchronizer
    @Injected private var removeDataController: RemoveDataController
    @Injected private var microphoneManager: MicrophoneManager
    @Injected private var bluetoothSessionRecorder: BluetoothSessionRecordingController
    @Injected private var activeSessionProvider: ActiveMobileSessionProvidingService

    private let responseHandler = AuthorizationHTTPResponseHandler()
    
    func logout(onEnd: @escaping () -> Void) throws {
        finishRecordingActiveSessions()
        if sessionSynchronizer.syncInProgress.value {
            var subscription: AnyCancellable?
            subscription = sessionSynchronizer.syncInProgress.receive(on: DispatchQueue.main).sink { [weak self] value in
                guard value == false else { return }
                self?.removeDataController.removeData()
                subscription?.cancel()
                onEnd()
            }
            return
        }
        // For logout we only care about uploading sessions before we remove everything
        sessionSynchronizer.triggerSynchronization(options: [.upload], completion: {
            DispatchQueue.main.async { self.removeDataController.removeData(); onEnd() }
        })
    }
    
    private func finishRecordingActiveSessions() {
        microphoneManager.stopRecording()
        guard let activeSessionUUID = activeSessionProvider.activeSession?.session.uuid else { return }
        // We don't want to save active sessions in the database when the user logs out
        bluetoothSessionRecorder.stopRecordingSession(with: activeSessionUUID, databaseChange: { _ in })
    }
}
