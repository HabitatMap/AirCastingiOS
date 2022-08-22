// Created by Lunar on 26/04/2022.
//

import Foundation
import Resolver

protocol RemoveDataController {
    func removeData()
}

final class DefaultRemoveDataController: RemoveDataController {
    @Injected private var microphone: Microphone
    @Injected private var deauthorizer: Deauthorizable
    @Injected private var dataEraser: DataEraser

    func removeData() {
        Log.info("[LOGOUT] Cancelling all pending requests")
        URLSession.shared.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
        if microphone.state != .notRecording {
            Log.info("[LOGOUT] Canceling recording session")
            try? microphone.stopRecording()
        }
        Log.info("[LOGOUT] Clearing user credentials")
        do {
            try deauthorizer.deauthorize()
            dataEraser.eraseAllData(completion: { [weak self] result in
                if case let .failure(error) = result {
                    self?.failLogout(with: error)
                }
            })
        } catch {
            failLogout(with: error)
        }
    }
    
    private func failLogout(with error: Error) {
        assertionFailure("[LOGOUT] Failed to log out \(error)")
    }
}
