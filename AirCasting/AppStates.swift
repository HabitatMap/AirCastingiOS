// Created by Lunar on 17/08/2021.
//

import SwiftUI

class AppStates: ObservableObject {
    
    var urlProvider: BaseURLProvider
    private var microphoneManager: MicrophoneManager
    private var observers = [NSObjectProtocol]()

    init(microphoneManager: MicrophoneManager, urlProvider: BaseURLProvider) {
        self.microphoneManager = microphoneManager
        self.urlProvider = urlProvider
        self.urlProvider.didAppEnterBackground = false
        // It is handling only microphone session for now
        #warning("Handle bluetooth session too - on crash and on start if any left")
        observers.append(
            NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { _ in
                self.urlProvider.didAppEnterBackground = false
                if microphoneManager.isRecording {
                    do {
                        try self.microphoneManager.stopRecording()
                    } catch {
                        Log.info("error when stopping mic session - \(error)")
                    }
                }
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { _ in
                self.urlProvider.didAppEnterBackground = true
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
                if urlProvider.didAppEnterBackground == false {
                    if microphoneManager.isRecording {
                        do {
                            try self.microphoneManager.stopRecording()
                        } catch {
                            Log.info("error when stopping mic session - \(error)")
                        }
                    }
                }
            }
        )
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }
}
