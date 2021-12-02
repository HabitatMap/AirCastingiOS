// Created by Lunar on 02/12/2021.
//

import Foundation
import Combine

protocol SDSyncRootViewModel: ObservableObject {
    var backendSyncCompleted: Bool { get set }
    var urlProvider: BaseURLProvider { get }
    func startBackendSync()
    func onAppearExecute()
}

class SDSyncRootViewModelDefault: SDSyncRootViewModel, ObservableObject {
    
    @Published var backendSyncCompleted: Bool = false
    private let sessionSynchronizer: SessionSynchronizer
    let urlProvider: BaseURLProvider
    
    init(sessionSynchronizer: SessionSynchronizer, urlProvider: BaseURLProvider) {
        self.sessionSynchronizer = sessionSynchronizer
        self.urlProvider = urlProvider
    }
    
    func startBackendSync() {
        sessionSynchronizer.triggerSynchronization() {
            DispatchQueue.main.async {
                self.backendSyncCompleted = true
            }
        }
    }
    
    func onAppearExecute() {
        guard !sessionSynchronizer.syncInProgress.value else {
            onCurrentSyncEnd { self.startBackendSync() }
            return
        }
    }
    
    private func onCurrentSyncEnd(_ completion: @escaping () -> Void) {
        guard sessionSynchronizer.syncInProgress.value else { completion(); return }
        var cancellable: AnyCancellable?
        cancellable = sessionSynchronizer.syncInProgress.sink { syncInProgress in
            guard !syncInProgress else { return }
            completion()
            cancellable?.cancel()
        }
    }
}

class DummySDSyncRootViewModelDefault: SDSyncRootViewModel, ObservableObject {
    
    @Published var backendSyncCompleted: Bool = false
    var urlProvider: BaseURLProvider
    
    init() {
        self.urlProvider = DummyURLProvider()
    }
    
    func startBackendSync() {
        print("startBackendSync")
    }
    
    func onAppearExecute() {
        print("onAppearExecute")
    }
    
}
