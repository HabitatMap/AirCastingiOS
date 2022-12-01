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

    private let responseHandler = AuthorizationHTTPResponseHandler()
    
    func logout(onEnd: @escaping () -> Void) throws {
        if sessionSynchronizer.syncInProgress.value {
            var subscription: AnyCancellable?
            subscription = sessionSynchronizer.syncInProgress.receive(on: DispatchQueue.main).sink { [weak self] value in
                guard value == false else { return }
                self?.end(onEnd: onEnd)
                subscription?.cancel()
            }
            return
        }
        // For logout we only care about uploading sessions before we remove everything
        sessionSynchronizer.triggerSynchronization(options: [.upload], completion: {
            DispatchQueue.main.async { self.end(onEnd: onEnd) }
        })
    }
    
    private func end(onEnd: @escaping () -> Void) {
        removeDataController.removeData()
        microphoneManager.stopRecording()
        onEnd()
    }
}
