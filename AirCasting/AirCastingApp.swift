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
    private let authorization = UserAuthenticationSession()
    private let syncScheduler: SynchronizationScheduler
    private var sessionSynchronizer: SessionSynchronizer
    private var sessionSynchronizerViewModel: DefaultSessionSynchronizationViewModel
    private let averagingService: AveragingService
    @Injected private var persistenceController: PersistenceController
    private let appBecameActive = PassthroughSubject<Void, Never>()
    private let sessionSynchronizationController: SessionSynchronizationController
    @ObservedObject private var offlineMessageViewModel: OfflineMessageViewModel
    private let lifeTimeEventsProvider = LifeTimeEventsProvider()
    private var cancellables: [AnyCancellable] = []
    let urlProvider = UserDefaultsBaseURLProvider()

    init() {
        AppBootstrap(firstRunInfoProvider: lifeTimeEventsProvider, deauthorizable: authorization).bootstrap()
        let synchronizationContextProvider = SessionSynchronizationService(client: URLSession.shared, authorization: authorization, responseValidator: DefaultHTTPResponseValidator(), urlProvider: urlProvider)
        let downloadService = SessionDownloadService(client: URLSession.shared, authorization: authorization, responseValidator: DefaultHTTPResponseValidator(), urlProvider: urlProvider)
        let uploadService = SessionUploadService(client: URLSession.shared, authorization: authorization, responseValidator: DefaultHTTPResponseValidator(), urlProvider: urlProvider)
        let syncStore = SessionSynchronizationDatabase()
        let unscheduledSyncController = SessionSynchronizationController(synchronizationContextProvider: synchronizationContextProvider,
                                                                         downstream: downloadService,
                                                                         upstream: uploadService,
                                                                         store: syncStore)
        sessionSynchronizerViewModel = DefaultSessionSynchronizationViewModel(syncSessionController: unscheduledSyncController)
        sessionSynchronizationController = unscheduledSyncController
        sessionSynchronizer = ScheduledSessionSynchronizerProxy(controller: unscheduledSyncController,
                                                                scheduler: DispatchQueue.global())
        averagingService = AveragingService(measurementStreamStorage: CoreDataMeasurementStreamStorage())
        syncScheduler = .init(synchronizer: sessionSynchronizer,
                              appBecameActive: appBecameActive.eraseToAnyPublisher(),
                              authorization: authorization)
        
        
        offlineMessageViewModel = .init()
        sessionSynchronizer.errorStream = offlineMessageViewModel
    }

    var body: some Scene {
        WindowGroup {
            RootAppView(sessionSynchronizer: sessionSynchronizer,
                        urlProvider: urlProvider)
                .environmentObject(sessionSynchronizerViewModel)
                .environmentObject(authorization)
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


