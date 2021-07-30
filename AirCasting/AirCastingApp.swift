//
//  AirCastingApp.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI
import Firebase
import Combine

@main
struct AirCastingApp: App {
    @Environment(\.scenePhase) var scenePhase
    private let authorization: UserAuthenticationSession
    private let syncScheduler: SynchronizationScheduler
    private let sessionSynchronizer: SessionSynchronizer
    private let microphoneMenager: MicrophoneManager
    private let persistenceController = PersistenceController.shared
    private let appBecameActive = PassthroughSubject<Void, Never>()
    private var cancellables: [AnyCancellable] = []

    init() {
        #if !DEBUG
        FirebaseApp.configure()
        #endif
        self.authorization = UserAuthenticationSession()
        let synchronizationContextProvider = SessionSynchronizationService(client: URLSession.shared, authorization: authorization, responseValidator: DefaultHTTPResponseValidator())
        let downloadService = SessionDownloadService(client: URLSession.shared, authorization: authorization, responseValidator: DefaultHTTPResponseValidator())
        let uploadService = SessionUploadService(client: URLSession.shared, authorization: authorization, responseValidator: DefaultHTTPResponseValidator())
        let syncStore = SessionSynchronizationDatabase(database: persistenceController)
        
        let unscheduledSyncController = SessionSynchronizationController(synchronizationContextProvider: synchronizationContextProvider,
                                                                         downstream: downloadService,
                                                                         upstream: uploadService,
                                                                         store: syncStore)
        sessionSynchronizer = ScheduledSessionSynchronizerProxy(controller: unscheduledSyncController,
                                                                scheduler: DispatchQueue.global())
        microphoneMenager = MicrophoneManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared), sessionSynchronizer: sessionSynchronizer)
        syncScheduler = .init(synchronizer: sessionSynchronizer,
                              appBecameActive: appBecameActive.eraseToAnyPublisher(),
                              periodicTimeInterval: 300,
                              authorization: authorization)
    }

    var body: some Scene {
        WindowGroup {
            RootAppView(sessionSynchronizer: sessionSynchronizer, persistenceController: persistenceController)
                .environmentObject(authorization)
                .environmentObject(microphoneMenager)
        }.onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .active:
                appBecameActive.send()
            case .background:
                break
            case .inactive:
                break
            @unknown default:
                fatalError()
            }
        }
    }
}

final class SynchronizationScheduler {
    private var cancellables: [AnyCancellable] = []
    
    init(synchronizer: SessionSynchronizer,
         appBecameActive: AnyPublisher<Void, Never>,
         periodicTimeInterval: TimeInterval,
         authorization: UserAuthenticationSession) {
        
        appBecameActive
            .filter { authorization.isLoggedIn }
            .sink {
                synchronizer.triggerSynchronization()
            }
            .store(in: &cancellables)
        
        Timer.publish(every: periodicTimeInterval, on: .current, in: .default)
            .autoconnect()
            .eraseToVoid()
            .filter { authorization.isLoggedIn }
            .sink {
                synchronizer.triggerSynchronization()
            }
            .store(in: &cancellables)
        
        authorization
            .$isLoggedIn
            .removeDuplicates()
            .filter { $0 }
            .eraseToVoid()
            .sink {
                synchronizer.triggerSynchronization()
            }
            .store(in: &cancellables)
        
    }
}
