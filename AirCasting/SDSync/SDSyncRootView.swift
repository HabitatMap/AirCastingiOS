// Created by Lunar on 16/11/2021.
//

import SwiftUI
import CoreBluetooth
import Combine

struct SDSyncRootView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject private var finishAndSyncButtonTapped: FinishAndSyncButtonTapped
    let sessionSynchronizer: SessionSynchronizer
    let urlProvider: BaseURLProvider
    
    @State private var backendSyncCompleted = false
    
    init(sessionSynchronizer: SessionSynchronizer, urlProvider: BaseURLProvider) {
        self.sessionSynchronizer = sessionSynchronizer
        self.urlProvider = urlProvider
    }
    
    var body: some View {
        NavigationView {
            Text("Syncing")
                .background(
                    NavigationLink(
                        destination: SelectPeripheralView(creatingSessionFlowContinues: .constant(true), urlProvider: urlProvider, syncMode: true),
                        isActive: $backendSyncCompleted,
                        label: {
                            EmptyView()
                        })
                )
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: backButton)
            
        }
        .onAppear() {
            guard !sessionSynchronizer.syncInProgress.value else {
                onCurrentSyncEnd { self.startBackendSync() }
                return
            }
            finishAndSyncButtonTapped.finishAndSyncButtonWasTapped = false
            startBackendSync()
        }
    }
    
    func startBackendSync() {
        sessionSynchronizer.triggerSynchronization() {
            self.backendSyncCompleted = true
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

    var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }, label: {
            HStack {
                Text("Cancel")
            }
        })
    }
}

#if DEBUG
struct SDSyncRootView_Previews: PreviewProvider {
    static var previews: some View {
        SDSyncRootView(sessionSynchronizer: DummySessionSynchronizer(), urlProvider: DummyURLProvider())
    }
}
#endif
