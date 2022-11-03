//
//  AirCastingApp.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI
import Combine
import Resolver

@main
struct AirCastingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.scenePhase) var scenePhase
    @State var shouldProtect = false
    private let syncScheduler: SynchronizationScheduler
    @Injected private var sessionSynchronizer: SessionSynchronizer
    @Injected private var persistenceController: PersistenceController
    @Injected private var mobilePeripheralSessionManager: MobilePeripheralSessionManager
    @Injected private var microphone: Microphone
    private let appBecameActive = PassthroughSubject<Void, Never>()
    @ObservedObject private var offlineMessageViewModel: OfflineMessageViewModel
    private var cancellables: [AnyCancellable] = []

    init() {
        AppBootstrap().bootstrap()
        // _ = Resolver.resolve(ReconnectionController.self)
        syncScheduler = .init(appBecameActive: appBecameActive.eraseToAnyPublisher())
        offlineMessageViewModel = .init()
        sessionSynchronizer.errorStream = offlineMessageViewModel
    }

    var body: some Scene {
        WindowGroup {
            RootAppView()
                .fullScreenCover(isPresented: $shouldProtect, content: {
                    ProtectedScreen()
                })
                .alert(isPresented: $offlineMessageViewModel.showOfflineMessage, content: { Alert.offlineAlert })
        }.onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .active:
                shouldProtect = false
                persistenceController.uiSuspended = false
                appBecameActive.send()
            case .background, .inactive:
                if mobilePeripheralSessionManager.isMobileSessionActive || microphone.state == .recording {
                    shouldProtect = true
                }
                persistenceController.uiSuspended = true
            @unknown default:
                fatalError()
            }
        }
    }
}

final class SynchronizationScheduler {
    private var cancellables: [AnyCancellable] = []
    @Injected private var synchronizer: SessionSynchronizer
    @Injected private var authorization: UserAuthenticationSession
    
    init(appBecameActive: AnyPublisher<Void, Never>) {
        
        appBecameActive
            .filter { self.authorization.isLoggedIn }
            .sink {
                self.synchronizer.triggerSynchronization()
            }
            .store(in: &cancellables)
        
        authorization
            .$isLoggedIn
            .removeDuplicates()
            .scan((nil, nil)) {
                ($0.1, $1)
            }
            .logVerbose { "Logged in state changed from \(String(describing: $0.0)) to \(String(describing: $0.1))" }
            .compactMap {
                guard let _ = $0.0 else { return nil }
                guard let new = $0.1 else { return nil }
                return new
            }
            .filter { $0 }
            .eraseToVoid()
            .sink {
                self.synchronizer.triggerSynchronization()
            }
            .store(in: &cancellables)
        
    }
}


