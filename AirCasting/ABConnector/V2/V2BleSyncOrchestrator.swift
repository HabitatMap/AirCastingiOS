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

    private weak var configurator: AirBeamMiniV2Configurator?
    private let queue = DispatchQueue(label: "ab.v2.sync.orchestrator")

    private var receivedBytes: Int = 0
    private var expectedBytes: UInt64?
    private var collectedRecords: [V2SyncRecord] = []
    private var progressHandler: ((Progress) -> Void)?
    private var completionHandler: ((Result<[V2SyncRecord], Error>) -> Void)?
    private var isRunning: Bool = false
    private var cancelled: Bool = false

    init(configurator: AirBeamMiniV2Configurator) {
        self.configurator = configurator
    }

    /// Kick off a manual sync. `progress` is called from a background queue
    /// after every chunk; UI must marshal to main. `completion` fires once
    /// with the accumulated records on Ready or with a `SyncError` on failure
    /// or cancellation.
    func start(progress: @escaping (Progress) -> Void,
               completion: @escaping (Result<[V2SyncRecord], Error>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { completion(.failure(SyncError.configuratorReleased)); return }
            guard !self.isRunning else { completion(.failure(SyncError.alreadyRunning)); return }
            guard let configurator = self.configurator else {
                completion(.failure(SyncError.configuratorReleased)); return
            }
            self.isRunning = true
            self.cancelled = false
            self.receivedBytes = 0
            self.expectedBytes = nil
            self.collectedRecords.removeAll()
            self.progressHandler = progress
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
            self.collectedRecords.append(contentsOf: records)
            self.emitProgressLocked()
        }
    }

    func handleReady() {
        queue.async { [weak self] in
            guard let self = self, self.isRunning else { return }
            self.isRunning = false
            let records = self.collectedRecords
            let total = self.receivedBytes
            let expected = self.expectedBytes
            // Reconciliation: device-reported on-disk size (expected) vs received.
            // A byte shortfall means the transfer dropped records the device still
            // held (device-vs-app loss), distinct from expected being small to
            // begin with (device never recorded them).
            Log.info("[V2SYNC] manual sync complete: records=\(records.count) receivedBytes=\(total) expectedBytes=\(expected.map(String.init) ?? "nil") ≈expectedRecords=\(expected.map { String($0 / 8) } ?? "nil") byteShortfall=\(expected.map { Int($0) - total } ?? 0)")
            let completion = self.completionHandler
            self.completionHandler = nil
            self.progressHandler?(Progress(receivedBytes: total,
                                           expectedBytes: expected,
                                           percent: 100))
            self.progressHandler = nil
            self.collectedRecords.removeAll()
            self.configurator?.endManualSync(orchestrator: self)
            if self.cancelled {
                completion?(.failure(SyncError.cancelled))
            } else {
                completion?(.success(records))
            }
        }
    }

    func handleNack(_ error: V2BinaryProtocol.NackError, raw: UInt8) {
        queue.async { [weak self] in
            guard let self = self, self.isRunning else { return }
            self.isRunning = false
            let completion = self.completionHandler
            self.completionHandler = nil
            self.progressHandler = nil
            self.collectedRecords.removeAll()
            self.configurator?.endManualSync(orchestrator: self)
            completion?(.failure(SyncError.nack(error, raw: raw)))
        }
    }

    func handleAbort(_ error: Error) {
        queue.async { [weak self] in
            guard let self = self, self.isRunning else { return }
            self.isRunning = false
            let completion = self.completionHandler
            self.completionHandler = nil
            self.progressHandler = nil
            self.collectedRecords.removeAll()
            self.configurator?.endManualSync(orchestrator: self)
            completion?(.failure(error))
        }
    }

    private func emitProgressLocked() {
        let pct: Int
        if let expected = expectedBytes, expected > 0 {
            let raw = Int((Double(receivedBytes) / Double(expected)) * 100)
            pct = max(0, min(99, raw))
        } else {
            pct = 0
        }
        progressHandler?(Progress(receivedBytes: receivedBytes,
                                  expectedBytes: expectedBytes,
                                  percent: pct))
    }
}
