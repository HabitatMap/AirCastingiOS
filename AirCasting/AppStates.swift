// Created by Lunar on 17/08/2021.
//

import SwiftUI

class AppStates: ObservableObject {
    private var microphoneManager: MicrophoneManager
    private var observers = [NSObjectProtocol]()

    init(microphoneManager: MicrophoneManager) {
        self.microphoneManager = microphoneManager

        observers.append(
            NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { _ in
                if microphoneManager.isRecording {
                    do {
                        try self.microphoneManager.stopRecording()
                    } catch {
                        Log.info("error when stopping mic session - \(error)")
                    }
                }
            }
        )
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }
}
