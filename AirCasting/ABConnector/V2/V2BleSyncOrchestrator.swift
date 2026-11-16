// Created by Lunar on Phase 6 — BLE manual sync.
//

import Foundation

/// Drives the BLE-only manual sync flow (`StartBleSync 0x16`).
///
/// Sequence (firmware contract):
///   1. App writes `0x16` to Command.
///   2. Device replies `Ack (0x20)` on Response.
///   3. Device emits Status `ReadyToSync (0x03)` with `file_size_u64_LE` ~100 ms
///      before the first chunk. The orchestrator must already be observing the
///      Status characteristic so the file size is captured in time to drive
///      progress — awaiting it after the post-stream Ready is too late.
///   4. Firmware streams stored records on the Sync characteristic; each
///      indication payload is `[count_u8, padding_2B, count × 8B records]` and
///      each on-disk block is `5 + 8 × count` bytes (the basis of the progress
///      computation; matches the firmware's LittleFS framing).
///   5. Device emits `Ready (0x22)` on Response when all records have been sent
///      and auto-clears storage. The app does NOT send `DiscardSession (0x11)`
///      on success — firmware handles cleanup itself.
///
/// Failure modes:
///   - `Nack (0x06 SyncFailed)` — an indication did not ACK; firmware stops
///     and **retains records** on device for retry.
///   - `Nack (0x04 ClearStorageFailed)` — post-stream storage wipe failed.
///
/// Cancellation: the host can `cancelAndDiscard()` mid-stream — firmware
/// honors `DiscardSession (0x11)` even with `StartBleSync` in flight, wiping
/// on-device storage. Records collected so far are dropped (the
/// "Discard & Finish" branch on the finish-path dialog).
final class V2BleSyncOrchestrator {
    enum SyncError: Error, LocalizedError {
        case alreadyRunning
        case writeFailed(Error)
        case nack(V2BinaryProtocol.NackError, raw: UInt8)
        case cancelled
        case configuratorReleased

        var errorDescription: String? {
            switch self {
            case .alreadyRunning:
                return "A manual sync is already in progress."
            case .writeFailed(let error):
                return "Could not start sync: \(error.localizedDescription)"
            case .nack(let kind, _):
                switch kind {
                case .syncFailed:
                    return "AirBeam reported a sync failure. Measurements remain on the device."
                case .clearOrSyncStorageFailed:
                    return "AirBeam failed to clear stored measurements after sync."
                default:
                    return "AirBeam rejected the sync request."
                }
            case .cancelled:
                return "Sync was cancelled."
            case .configuratorReleased:
                return "AirBeam connection was released before sync completed."
            }
        }
    }

    struct Progress: Equatable {
        let receivedBytes: Int
        let expectedBytes: UInt64?
        /// 0..100; clamped to 99 mid-stream so the UI never shows 100% before
        /// the post-stream `Ready (0x22)` lands.
        let percent: Int
    }

    /// Terminal summary. The records themselves are streamed to the DB in
    /// bounded windows as they arrive (`persistWindow`), so the orchestrator no
    /// longer hands back the whole session — only the counts needed for logging
    /// and byte reconciliation.
    struct Summary: Equatable {
        let recordCount: Int
        let receivedBytes: Int
        let expectedBytes: UInt64?
    }

    /// Max records buffered before a flush to `persistWindow`. Bounds RAM (and
    /// the data lost if the app is killed mid-finish) to one window instead of
    /// the entire full-flash session, while keeping each CoreData transaction
    /// large enough to avoid the per-indication save storm.
    private static let windowSize = 1000

    private weak var configurator: AirBeamMiniV2Configurator?
    private let queue = DispatchQueue(label: "ab.v2.sync.orchestrator")

    private var receivedBytes: Int = 0
    private var receivedRecordCount: Int = 0
    /// Records CONFIRMED committed to the DB (persist-path progress driver).
    /// When persisting, the progress bar tracks this — not bytes received — so it
    /// keeps moving while the DB consumer drains a backlog instead of freezing
    /// near 100% with the receive already done.
    private var persistedRecordCount: Int = 0
    /// True when a `persistWindow` sink was installed at `start` — i.e. progress
    /// should be driven off persisted records rather than received records.
    private var persistTracking: Bool = false
    private var expectedBytes: UInt64?
    /// Bounded buffer flushed to `persistWindow` every `windowSize` records.
    private var pendingWindow: [V2SyncRecord] = []
    private var progressHandler: ((Progress) -> Void)?
    /// Called on `queue` with each full window (and the tail on terminal) so the
    /// owner can persist incrementally. The second argument is a completion the
    /// owner invokes (with the number of records committed) once the batch lands
    /// in the DB, so progress can advance on real persistence. Nil for drain-only
    /// flows (e.g. the start-path sync that discards records).
    private var persistWindow: (([V2SyncRecord], @escaping (Int) -> Void) -> Void)?
    /// Called on terminal, after the last window flush, to drain the persistence
    /// pipeline; its callback delivers the final completion so callers can
    /// finalize the session knowing every window has committed.
    private var finalizeHandler: ((@escaping () -> Void) -> Void)?
    private var completionHandler: ((Result<Summary, Error>) -> Void)?
    private var isRunning: Bool = false
    private var cancelled: Bool = false

    init(configurator: AirBeamMiniV2Configurator) {
        self.configurator = configurator
    }

    /// Kick off a manual sync. `progress` is called from a background queue
    /// after every chunk; UI must marshal to main. Records are streamed to
    /// `persistWindow` in bounded windows as they arrive (nil = drain-only, no
    /// persistence). On terminal, `finalize` drains the persistence pipeline and
    /// its callback delivers `completion` — which fires once with a `Summary` on
    /// Ready or a `SyncError` on failure/cancellation.
    func start(progress: @escaping (Progress) -> Void,
               persistWindow: (([V2SyncRecord], @escaping (Int) -> Void) -> Void)? = nil,
               finalize: ((@escaping () -> Void) -> Void)? = nil,
               completion: @escaping (Result<Summary, Error>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { completion(.failure(SyncError.configuratorReleased)); return }
            guard !self.isRunning else { completion(.failure(SyncError.alreadyRunning)); return }
            guard let configurator = self.configurator else {
                completion(.failure(SyncError.configuratorReleased)); return
            }
            self.isRunning = true
            self.cancelled = false
            self.receivedBytes = 0
            self.receivedRecordCount = 0
            self.persistedRecordCount = 0
            self.persistTracking = persistWindow != nil
            self.expectedBytes = nil
            self.pendingWindow.removeAll(keepingCapacity: true)
            self.progressHandler = progress
            self.persistWindow = persistWindow
            self.finalizeHandler = finalize
            self.completionHandler = completion

            // Seed file_size from the current Status if it already carries one
            // (`HasSavedSession` from the start path), so the ETA hint can be
            // shown immediately and the progress bar doesn't sit at 0 while
            // waiting for `ReadyToSync (0x03)`.
            if let cached = configurator.lastStatus?.fileSize {
                self.expectedBytes = cached
            }

            configurator.beginManualSync(orchestrator: self)
        }
    }

    /// Cancel mid-stream — sends `DiscardSession (0x11)`. The pending
    /// completion resolves with `.failure(.cancelled)`. Collected records are
    /// dropped on this branch — caller must NOT persist them.
    func cancelAndDiscard() {
        queue.async { [weak self] in
            guard let self = self, self.isRunning, !self.cancelled else { return }
            self.cancelled = true
            self.configurator?.cancelManualSync(orchestrator: self)
        }
    }

    // MARK: - Hooks called by AirBeamMiniV2Configurator while a sync is in flight

    func handleReadyToSync(fileSize: UInt64) {
        queue.async { [weak self] in
            guard let self = self, self.isRunning else { return }
            self.expectedBytes = fileSize
            self.emitProgressLocked()
        }
    }

    func handleSyncChunk(_ data: Data) {
        queue.async { [weak self] in
            guard let self = self, self.isRunning else { return }
            // On-disk block framing: [0xAB, 0xBA, count_u8, count × 8B records, xor_u8]
            //   = 5 + 8 × count bytes. The BLE indication payload is
            //   [count_u8, 2B padding, count × 8B records] — the same records
            //   wrapped in a different header. Use the on-disk byte count for
            //   progress so it matches the firmware's `file_size` metric.
            guard let records = V2MeasurementParser.parseSyncChunk(data) else {
                Log.warning("V2 manual sync: parseSyncChunk failed for \(data.count)B chunk")
                return
            }
            self.receivedBytes += 5 + 8 * records.count
            self.receivedRecordCount += records.count
            self.pendingWindow.append(contentsOf: records)
            if self.pendingWindow.count >= Self.windowSize {
                self.flushWindowLocked()
            }
            self.emitProgressLocked()
        }
    }

    /// Flush the buffered window to `persistWindow`. No-op when empty or when no
    /// sink is installed (drain-only sync). Runs on `queue`. The owner reports
    /// the committed count back so progress advances on real persistence.
    private func flushWindowLocked() {
        guard !pendingWindow.isEmpty else { return }
        let window = pendingWindow
        pendingWindow.removeAll(keepingCapacity: true)
        persistWindow?(window) { [weak self] persistedCount in
            self?.queue.async {
                guard let self = self else { return }
                self.persistedRecordCount += persistedCount
                self.emitProgressLocked()
            }
        }
    }

    func handleReady() {
        queue.async { [weak self] in
            guard let self = self, self.isRunning else { return }
            self.isRunning = false
            // Persist the tail window before summarising. Records streamed so
            // far are already committed; this flushes the last partial window.
            self.flushWindowLocked()
            let total = self.receivedBytes
            let expected = self.expectedBytes
            // Reconciliation: device-reported on-disk size (expected) vs received.
            // A byte shortfall means the transfer dropped records the device still
            // held (device-vs-app loss), distinct from expected being small to
            // begin with (device never recorded them).
            Log.info("[V2SYNC] manual sync complete: records=\(self.receivedRecordCount) receivedBytes=\(total) expectedBytes=\(expected.map(String.init) ?? "nil") ≈expectedRecords=\(expected.map { String($0 / 8) } ?? "nil") byteShortfall=\(expected.map { Int($0) - total } ?? 0)")
            let summary = Summary(recordCount: self.receivedRecordCount,
                                  receivedBytes: total,
                                  expectedBytes: expected)
            self.progressHandler?(Progress(receivedBytes: total,
                                           expectedBytes: expected,
                                           percent: 100))
            self.progressHandler = nil
            let cancelled = self.cancelled
            self.finishTerminalLocked(cancelled ? .failure(SyncError.cancelled) : .success(summary))
        }
    }

    func handleNack(_ error: V2BinaryProtocol.NackError, raw: UInt8) {
        queue.async { [weak self] in
            guard let self = self, self.isRunning else { return }
            self.isRunning = false
            // Persist what streamed so far; a re-sync dedups via the unique
            // (measurementStream,time) constraint, and syncFailed retains the
            // records on the device for retry.
            self.flushWindowLocked()
            self.progressHandler = nil
            self.finishTerminalLocked(.failure(SyncError.nack(error, raw: raw)))
        }
    }

    func handleAbort(_ error: Error) {
        queue.async { [weak self] in
            guard let self = self, self.isRunning else { return }
            self.isRunning = false
            self.flushWindowLocked()
            self.progressHandler = nil
            self.finishTerminalLocked(.failure(error))
        }
    }

    /// Shared terminal tail: clear per-run handlers, drain the persistence
    /// pipeline via `finalize` (if any), then deliver `completion`. Runs on
    /// `queue`; `completion` fires after every window has committed.
    private func finishTerminalLocked(_ result: Result<Summary, Error>) {
        let completion = self.completionHandler
        self.completionHandler = nil
        self.persistWindow = nil
        let finalize = self.finalizeHandler
        self.finalizeHandler = nil
        self.pendingWindow.removeAll(keepingCapacity: false)
        self.configurator?.endManualSync(orchestrator: self)
        let deliver: () -> Void = { completion?(result) }
        if let finalize = finalize {
            finalize(deliver)
        } else {
            deliver()
        }
    }

    private func emitProgressLocked() {
        let pct: Int
        if let expected = expectedBytes, expected > 0 {
            // Denominator in records (~8 on-disk bytes each). When persisting,
            // drive the bar off records actually committed to the DB so it keeps
            // moving while a save backlog drains instead of freezing once receive
            // completes; otherwise (drain-only) track received records.
            let expectedRecords = Double(expected) / 8.0
            let done = Double(persistTracking ? persistedRecordCount : receivedRecordCount)
            let raw = Int((done / expectedRecords) * 100)
            pct = max(0, min(99, raw))
        } else {
            pct = 0
        }
        progressHandler?(Progress(receivedBytes: receivedBytes,
                                  expectedBytes: expectedBytes,
                                  percent: pct))
    }
}
