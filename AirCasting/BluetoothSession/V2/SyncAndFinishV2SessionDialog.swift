// Created by Lunar on Phase 6 — BLE manual sync.
//

import SwiftUI
import AirCastingStyling
import Resolver

/// Chained after the standard `FinishSessionConfirmationDialog` when the
/// device still has stored measurements (`hasSavedMeasurements ||
/// isActiveSyncDraining` at confirm-time). Auto-starts `StartBleSync (0x16)`
/// on open so `ReadyToSync (0x03)` lands with a fresh `file_size` and the ETA
/// hint reflects the latest state. Non-cancelable (no backdrop dismiss).
///
/// Visuals match the Android `SyncAndFinishV2SessionDialog`: per-state title,
/// no separate progress bar (progress lives inside the disabled primary
/// button), success → "Done", failure → "Continue".
struct SyncAndFinishV2SessionDialog: View {
    @StateObject var viewModel: SyncAndFinishV2SessionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(titleText)
                .font(Fonts.muliBoldHeading1)
                .foregroundColor(.darkBlue)
            descriptionText
                .font(Fonts.muliRegularHeading3)
                .foregroundColor(.aircastingGray)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 12) {
                switch viewModel.state {
                case .syncing:
                    Button(action: {}) {
                        Text(primarySyncingButtonText)
                    }
                    .buttonStyle(BlueButtonStyle())
                    .disabled(true)
                    Button(action: { viewModel.discardAndFinish() }) {
                        Text(Strings.SyncAndFinishV2SessionDialog.discardAndFinishButton)
                    }
                    .buttonStyle(BlueTextButtonStyle())
                case .succeeded:
                    Button(action: { viewModel.finish() }) {
                        Text(Strings.SyncAndFinishV2SessionDialog.doneButton)
                    }
                    .buttonStyle(BlueButtonStyle())
                case .failed:
                    Button(action: { viewModel.finish() }) {
                        Text(Strings.SyncAndFinishV2SessionDialog.continueButton)
                    }
                    .buttonStyle(BlueButtonStyle())
                }
            }
        }
        .padding()
        .interactiveDismissDisabled(true)
    }

    private var titleText: String {
        switch viewModel.state {
        case .syncing: return Strings.SyncAndFinishV2SessionDialog.title
        case .succeeded: return Strings.SyncAndFinishV2SessionDialog.succeededTitle
        case .failed: return Strings.SyncAndFinishV2SessionDialog.failedTitle
        }
    }

    private var primarySyncingButtonText: String {
        if viewModel.progressPercent <= 0 {
            return Strings.SyncAndFinishV2SessionDialog.preparingButton
        }
        return String(format: Strings.SyncAndFinishV2SessionDialog.syncingProgressFormat,
                      viewModel.progressPercent)
    }

    private var descriptionText: Text {
        switch viewModel.descriptionState {
        case .initial(let eta):
            if let eta = eta {
                return Text(Strings.SyncAndFinishV2SessionDialog.descriptionPrefix)
                    + Text(Strings.SyncAndFinishV2SessionDialog.descriptionEtaPrefix + eta).bold()
                    + Text(Strings.SyncAndFinishV2SessionDialog.descriptionSuffix)
            }
            return Text(Strings.SyncAndFinishV2SessionDialog.descriptionNoEta)
        case .plain(let body):
            return Text(body)
        }
    }
}

final class SyncAndFinishV2SessionViewModel: ObservableObject {
    enum State: Equatable {
        case syncing
        case succeeded
        case failed
    }

    enum DescriptionState {
        case initial(eta: String?)
        case plain(String)
    }

    @Published private(set) var state: State = .syncing
    @Published private(set) var progressPercent: Int = 0
    @Published private(set) var descriptionState: DescriptionState

    private let configurator: AirBeamMiniV2Configurator
    private let onFinish: (Bool) -> Void
    private var orchestrator: V2BleSyncOrchestrator?
    private var pendingRecords: [V2SyncRecord] = []

    init(configurator: AirBeamMiniV2Configurator,
         onFinish: @escaping (Bool) -> Void) {
        self.configurator = configurator
        self.onFinish = onFinish
        let fileSize = configurator.lastStatus?.fileSize
        self.descriptionState = .initial(eta: Self.etaString(fileSize: fileSize))
        startSync()
    }

    private func startSync() {
        state = .syncing
        progressPercent = 0
        let orchestrator = configurator.makeManualSyncOrchestrator()
        self.orchestrator = orchestrator
        pendingRecords.removeAll()
        orchestrator.start(progress: { [weak self] progress in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.progressPercent = progress.percent
                if let expected = progress.expectedBytes,
                   case .initial = self.descriptionState {
                    self.descriptionState = .initial(eta: Self.etaString(fileSize: expected))
                }
            }
        }, completion: { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let records):
                    self.pendingRecords = records
                    self.state = .succeeded
                    self.descriptionState = .plain(Strings.SyncAndFinishV2SessionDialog.syncSucceededDescription)
                case .failure(let error):
                    Log.error("V2 finish-path manual sync failed: \(error)")
                    self.state = .failed
                    self.descriptionState = .plain(Strings.SyncAndFinishV2SessionDialog.syncFailedDescription)
                }
            }
        })
    }

    /// Mid-stream cancel + finish. Records collected so far are dropped; the
    /// `0x11 DiscardSession` wipes on-device storage.
    func discardAndFinish() {
        orchestrator?.cancelAndDiscard()
        pendingRecords.removeAll()
        onFinish(true)
    }

    /// Post-success or post-failure finish. On success, the collected records
    /// are persisted to the local DB before the session is marked FINISHED.
    func finish() {
        if state == .succeeded, !pendingRecords.isEmpty {
            configurator.persistManualSyncRecords(pendingRecords)
            pendingRecords.removeAll()
        }
        onFinish(true)
    }

    private static func etaString(fileSize: UInt64?) -> String? {
        guard let fileSize = fileSize, fileSize > 0 else { return nil }
        let seconds = V2BinaryProtocol.estimateSyncSeconds(fileSize: fileSize)
        guard seconds > 0 else { return nil }
        return formatDuration(seconds: seconds)
    }

    private static func formatDuration(seconds: Int) -> String {
        if seconds < 60 {
            return String(format: Strings.SyncBeforeNewV2SessionDialog.secondsFormat, seconds)
        }
        let minutes = (seconds + 59) / 60
        return String(format: Strings.SyncBeforeNewV2SessionDialog.minutesFormat, minutes)
    }
}
