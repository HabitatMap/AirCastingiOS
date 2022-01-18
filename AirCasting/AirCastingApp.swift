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
    private let syncScheduler: SynchronizationScheduler
    @Injected private var sessionSynchronizer: SessionSynchronizer
    @Injected private var persistenceController: PersistenceController
    private let appBecameActive = PassthroughSubject<Void, Never>()
    @ObservedObject private var offlineMessageViewModel: OfflineMessageViewModel
    private var cancellables: [AnyCancellable] = []

    init() {
        AppBootstrap().bootstrap()
        syncScheduler = .init(appBecameActive: appBecameActive.eraseToAnyPublisher())
        offlineMessageViewModel = .init()
        sessionSynchronizer.errorStream = offlineMessageViewModel
    }

    var body: some Scene {
        WindowGroup {
            RootAppView()
                .alert(isPresented: $offlineMessageViewModel.showOfflineMessage, content: { Alert.offlineAlert })
        }.onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .active:
                persistenceController.uiSuspended = false
                appBecameActive.send()
            case .background, .inactive:
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
            .filter { $0 }
            .eraseToVoid()
            .sink {
                self.synchronizer.triggerSynchronization()
            }
            .store(in: &cancellables)
        
    }
}


