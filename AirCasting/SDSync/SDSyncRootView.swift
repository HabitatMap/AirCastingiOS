// Created by Lunar on 16/11/2021.
//

import SwiftUI
import CoreBluetooth
import Combine

struct SDSyncRootView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var bluetoothManager: BluetoothManager
//    @EnvironmentObject var sdSyncController: SDSyncController
    let sessionSynchronizer: SessionSynchronizer
    var viewModel: SDSyncViewModel
    let urlProvider: BaseURLProvider
    
    @State private var backendSyncCompleted = false
    
    init(sessionSynchronizer: SessionSynchronizer, sdSyncController: SDSyncController, urlProvider: BaseURLProvider) {
        viewModel = SDSyncViewModel(sessionSynchronizer: sessionSynchronizer, sdSyncController: sdSyncController)
//        viewModel.startSync()
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
            if CBCentralManager.authorization == .allowedAlways {
                // it triggers the bluetooth searching on the appearing time
                _ = bluetoothManager.centralManager
                bluetoothManager.startScanning()
            }
            guard !sessionSynchronizer.syncInProgress.value else {
                onCurrentSyncEnd { self.startBackendSync() }
                return
            }
            
            startBackendSync()
        }
    }
    
    func startBackendSync() {
        Log.info("## Start sync")
        sessionSynchronizer.triggerSynchronization() {
            Log.info("## ended sync with backed")
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

//#if DEBUG
//struct SDSyncRootView_Previews: PreviewProvider {
//    static var previews: some View {
//        SDSyncRootView(sessionSynchronizer: DummySessionSynchronizer())
//    }
//}
//#endif
