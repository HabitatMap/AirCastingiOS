//
//  AirCastingApp.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI
import Combine

@main
struct AirCastingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.scenePhase) var scenePhase
    private let authorization = UserAuthenticationSession()
    private let syncScheduler: SynchronizationScheduler
    private let microphoneManager: MicrophoneManager
    private var sessionSynchronizer: SessionSynchronizer
    private var sessionSynchronizerViewModel: DefaultSessionSynchronizationViewModel
    private let averagingService: AveragingService
    private let persistenceController = PersistenceController.shared
    private let appBecameActive = PassthroughSubject<Void, Never>()
    private let sessionSynchronizationController: SessionSynchronizationController
    @ObservedObject private var offlineMessageViewModel: OfflineMessageViewModel
    private let lifeTimeEventsProvider = LifeTimeEventsProvider()
    private var cancellables: [AnyCancellable] = []

    init() {
        AppBootstrap(firstRunInfoProvider: lifeTimeEventsProvider, deauthorizable: authorization).bootstrap()
        let synchronizationContextProvider = SessionSynchronizationService(client: URLSession.shared, authorization: authorization, responseValidator: DefaultHTTPResponseValidator())
        let downloadService = SessionDownloadService(client: URLSession.shared, authorization: authorization, responseValidator: DefaultHTTPResponseValidator())
        let uploadService = SessionUploadService(client: URLSession.shared, authorization: authorization, responseValidator: DefaultHTTPResponseValidator())
        let syncStore = SessionSynchronizationDatabase(database: persistenceController)
        let unscheduledSyncController = SessionSynchronizationController(synchronizationContextProvider: synchronizationContextProvider,
                                                                         downstream: downloadService,
                                                                         upstream: uploadService,
                                                                         store: syncStore)
        sessionSynchronizerViewModel = DefaultSessionSynchronizationViewModel(syncSessionController: unscheduledSyncController)
        sessionSynchronizationController = unscheduledSyncController
        sessionSynchronizer = ScheduledSessionSynchronizerProxy(controller: unscheduledSyncController,
                                                                scheduler: DispatchQueue.global())
        microphoneManager = MicrophoneManager(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared))
        averagingService = AveragingService(measurementStreamStorage: CoreDataMeasurementStreamStorage(persistenceController: PersistenceController.shared))
        syncScheduler = .init(synchronizer: sessionSynchronizer,
                              appBecameActive: appBecameActive.eraseToAnyPublisher(),
                              authorization: authorization)
        
        
        offlineMessageViewModel = .init()
        sessionSynchronizer.errorStream = offlineMessageViewModel
    }

    var body: some Scene {
        WindowGroup {
            RootAppView(sessionSynchronizer: sessionSynchronizer, persistenceController: persistenceController)
                .environmentObject(sessionSynchronizerViewModel)
                .environmentObject(authorization)
                .environmentObject(microphoneManager)
                .environmentObject(averagingService)
                .environmentObject(lifeTimeEventsProvider)
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
    
    init(synchronizer: SessionSynchronizer,
         appBecameActive: AnyPublisher<Void, Never>,
         authorization: UserAuthenticationSession) {
        
        appBecameActive
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


