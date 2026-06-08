// Created by Lunar on Phase 6 — BLE manual sync.
//

import SwiftUI
import AirCastingStyling
import Resolver

/// Surfaced when the user picks a V2 AirBeam Mini that's in `HasSavedSession`
/// and wants to start a new session. Three actions: Sync (drives
/// `StartBleSync 0x16`, then proceeds with new-session config without bouncing
/// the BLE link), Discard (drives `DiscardSession 0x11` then proceeds), Cancel
/// (bails out of session creation entirely).
struct SyncBeforeNewV2SessionDialog: View {
    @StateObject var viewModel: SyncBeforeNewV2SessionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(Strings.SyncBeforeNewV2SessionDialog.title)
                .font(Fonts.muliBoldHeading1)
                .foregroundColor(.darkBlue)
            descriptionText
                .font(Fonts.muliRegularHeading3)
                .foregroundColor(.aircastingGray)
                .fixedSize(horizontal: false, vertical: true)
            if viewModel.isSyncing {
                ProgressView(value: Double(viewModel.progressPercent), total: 100)
                Text(String(format: Strings.SyncBeforeNewV2SessionDialog.progressFormat,
                            viewModel.progressPercent))
                    .font(Fonts.muliMediumHeading3)
                    .foregroundColor(.aircastingGray)
            }
            VStack(spacing: 12) {
                Button(action: { viewModel.tapSync() }) {
                    Text(Strings.SyncBeforeNewV2SessionDialog.syncButton)
                }
                .buttonStyle(BlueButtonStyle())
                .disabled(viewModel.isSyncing)

                Button(action: { viewModel.tapDiscard() }) {
                    Text(Strings.SyncBeforeNewV2SessionDialog.discardButton)
                }
                .buttonStyle(BlueButtonStyle())
                .disabled(viewModel.isSyncing)

                Button(action: { viewModel.tapCancel() }) {
                    Text(Strings.Commons.cancel)
                }
                .buttonStyle(BlueTextButtonStyle())
                .disabled(viewModel.isSyncing)
            }
        }
        .padding()
    }

    private var descriptionText: Text {
        switch viewModel.descriptionState {
        case .initial(let eta):
            return Text(Strings.SyncBeforeNewV2SessionDialog.descriptionPrefix)
                + Text(eta).bold()
                + Text(Strings.SyncBeforeNewV2SessionDialog.descriptionSuffix)
        case .plain(let body):
            return Text(body)
        }
    }
}

final class SyncBeforeNewV2SessionViewModel: ObservableObject {
    enum Outcome {
        case proceedWithNewSession
        case cancel
    }

    enum DescriptionState {
        /// Initial pre-sync prompt with a bold ETA hint. The first associated
        /// value is the localized ETA string (e.g. "12 sec." or "3 min.").
        case initial(eta: String)
        /// Post-sync state (in progress / failure) — single-line plain copy.
        case plain(String)
    }

    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var progressPercent: Int = 0
    @Published private(set) var descriptionState: DescriptionState

    private let configurator: AirBeamMiniV2Configurator
    private let estimatedSeconds: Int
    private let onResolved: (Outcome) -> Void
    private var orchestrator: V2BleSyncOrchestrator?

    init(configurator: AirBeamMiniV2Configurator,
         onResolved: @escaping (Outcome) -> Void) {
        self.configurator = configurator
        self.onResolved = onResolved
        let fileSize = configurator.lastStatus?.fileSize
        self.estimatedSeconds = V2BinaryProtocol.estimateSyncSeconds(fileSize: fileSize)
        self.descriptionState = .initial(
            eta: SyncBeforeNewV2SessionViewModel.formatDuration(seconds: V2BinaryProtocol.estimateSyncSeconds(fileSize: fileSize))
        )
    }

    func tapSync() {
        guard !isSyncing else { return }
        isSyncing = true
        progressPercent = 0
        descriptionState = .plain(Strings.SyncBeforeNewV2SessionDialog.syncingDescription)
        let orchestrator = configurator.makeManualSyncOrchestrator()
        self.orchestrator = orchestrator
        orchestrator.start(progress: { [weak self] progress in
            DispatchQueue.main.async {
                self?.progressPercent = progress.percent
            }
        }, completion: { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSyncing = false
                switch result {
                case .success(let records):
                    // Start-path Sync: records are NOT persisted because the
                    // device's stored session was a previous one. Firmware
                    // auto-clears on its Stop handler; we keep the BLE link
                    // open and proceed straight to NewSessionConfig.
                    Log.info("V2 start-path manual sync completed (\(records.count) records discarded — not the active session)")
                    self.onResolved(.proceedWithNewSession)
                case .failure(let error):
                    Log.error("V2 start-path manual sync failed: \(error)")
                    self.descriptionState = .plain(Strings.SyncBeforeNewV2SessionDialog.syncFailedDescription)
                }
            }
        })
    }

    func tapDiscard() {
        guard !isSyncing else { return }
        // Configurator's `configureMobileSession` already sends DiscardSession
        // on HasSavedSession; just proceed.
        onResolved(.proceedWithNewSession)
    }

    func tapCancel() {
        guard !isSyncing else { return }
        onResolved(.cancel)
    }

    private static func formatDuration(seconds: Int) -> String {
        if seconds < 60 {
            return String(format: Strings.SyncBeforeNewV2SessionDialog.secondsFormat, seconds)
        }
        let minutes = (seconds + 59) / 60
        return String(format: Strings.SyncBeforeNewV2SessionDialog.minutesFormat, minutes)
    }
}
