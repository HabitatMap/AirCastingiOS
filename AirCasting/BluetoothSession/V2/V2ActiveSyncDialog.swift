// Active-reconnect sync user-blocking dialog.
//
// Active-sync replay arrives as a burst of `Sync (0x16)` indications after
// BLE reconnect. Even with batched saves and the burst-suppression gate on
// `PersistenceController`, finishing the burst still runs one chunk's worth of
// CoreData inserts onto disk. The dialog blocks card↔graph↔map navigation
// while the burst is in flight so the user doesn't perceive lag and so
// backgrounding the app (which would resume UI propagation and stall the
// save chain) is discouraged.
//
// Driven by `Notification.Name.v2SyncDrainChanged` — already posted by
// `AirBeamMiniV2Configurator.bumpActiveSyncDrainingLocked`.

import SwiftUI
import AirCastingStyling

struct V2ActiveSyncDialog: View {
    var isFinalizing: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(Strings.V2ActiveSyncDialog.title)
                .font(Fonts.muliBoldHeading1)
                .foregroundColor(.darkBlue)
            Text(Strings.V2ActiveSyncDialog.description)
                .font(Fonts.muliRegularHeading3)
                .foregroundColor(.aircastingGray)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                ProgressView()
                Text(isFinalizing ? Strings.V2ActiveSyncDialog.finalizingLabel : Strings.V2ActiveSyncDialog.progressLabel)
                    .font(Fonts.muliRegularHeading3)
                    .foregroundColor(.aircastingGray)
            }
        }
        .padding()
        .interactiveDismissDisabled(true)
    }
}

/// Tracks the V2 active-sync drain state via NotificationCenter. Attach via
/// `.modifier(V2ActiveSyncDialogModifier())` on any view that should present
/// the dialog while a sync burst is in flight.
final class V2ActiveSyncObserver: ObservableObject {
    @Published private(set) var isDraining: Bool = false
    @Published private(set) var isFinalizing: Bool = false
    private var observer: NSObjectProtocol?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: .v2SyncDrainChanged,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self = self,
                  let info = note.userInfo,
                  let draining = info[AirCastingNotificationKeys.V2SyncDrainChanged.isDraining] as? Bool
            else { return }
            self.isDraining = draining
            self.isFinalizing = (info[AirCastingNotificationKeys.V2SyncDrainChanged.isFinalizing] as? Bool) ?? false
        }
    }

    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

struct V2ActiveSyncDialogModifier: ViewModifier {
    @StateObject private var observer = V2ActiveSyncObserver()

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: Binding(
                get: { observer.isDraining },
                set: { _ in /* dismissal driven by observer state only */ }
            )) {
                V2ActiveSyncDialog(isFinalizing: observer.isFinalizing)
            }
    }
}
