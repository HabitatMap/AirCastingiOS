// Created by Lunar on 30/04/2026.
//

import Foundation

/// Routes V2 Response-characteristic notifications to per-pending-command handlers.
/// One outstanding two-stage command (Ack→Ready) at a time. The dispatcher tracks
/// whether the very first `Ready` after a `NewSessionConfig`/`ContinueSession` has
/// fired so subsequent `Ready` notifications act as idempotent heartbeats only.
final class V2ResponseDispatcher {
    enum DispatchError: Error, LocalizedError {
        case nack(V2BinaryProtocol.NackError, raw: UInt8)
        case malformed

        var errorDescription: String? {
            switch self {
            case .nack(let kind, _):
                switch kind {
                case .invalidWifiCredentials:
                    return "WiFi credentials were rejected by the AirBeam. Please re-enter SSID and password."
                case .invalidConfig:
                    return "AirBeam could not start the session. Please try again."
                case .storageHasMeasurements:
                    return "AirBeam still has unsynced measurements stored."
                case .clearOrSyncStorageFailed:
                    return "AirBeam failed to clear / sync stored measurements."
                case .noSession:
                    return "AirBeam reported no active session."
                case .syncFailed:
                    return "AirBeam reported a sync failure. Measurements remain on the device."
                }
            case .malformed:
                return "AirBeam sent a malformed response."
            }
        }
    }

    private let lock = NSLock()

    // All access to these guarded by `lock`. Handlers are read+nil'd under lock
    // and then invoked OUTSIDE the lock so callers can re-enter the dispatcher
    // (e.g. arm the next Ack→Ready cycle) without deadlocking.
    private var ackHandler: ((Result<Void, Error>) -> Void)?
    private var readyHandler: ((Result<Void, Error>) -> Void)?
    private var sensorInfoHandler: ((Result<String, Error>) -> Void)?
    private var firstReadyConsumedStorage: Bool = false

    var firstReadyConsumed: Bool {
        lock.lock(); defer { lock.unlock() }
        return firstReadyConsumedStorage
    }

    func resetSessionStartGuard() {
        lock.lock(); defer { lock.unlock() }
        firstReadyConsumedStorage = false
    }

    /// Wait for an Ack, then a Ready. Calls `completion` on Ready or any failure.
    func awaitAckThenReady(completion: @escaping (Result<Void, Error>) -> Void) {
        lock.lock()
        ackHandler = { [weak self] result in
            switch result {
            case .success:
                self?.installReadyHandler(completion)
            case .failure(let err):
                completion(.failure(err))
            }
        }
        lock.unlock()
    }

    private func installReadyHandler(_ completion: @escaping (Result<Void, Error>) -> Void) {
        lock.lock()
        readyHandler = completion
        lock.unlock()
    }

    /// Wait for a single terminal Ready (e.g. DiscardSession). Forwards Nack as failure.
    func awaitReady(completion: @escaping (Result<Void, Error>) -> Void) {
        lock.lock()
        readyHandler = completion
        lock.unlock()
    }

    /// Wait for a SensorInfo (0x23) reply.
    func awaitSensorInfo(completion: @escaping (Result<String, Error>) -> Void) {
        lock.lock()
        sensorInfoHandler = completion
        lock.unlock()
    }

    /// Drop any pending handlers (used when tearing down). Fires each
    /// outstanding handler with `.failure(error)` so callers can clean up.
    func cancelAll(_ error: Error) {
        lock.lock()
        let ack = ackHandler; ackHandler = nil
        let ready = readyHandler; readyHandler = nil
        let sensor = sensorInfoHandler; sensorInfoHandler = nil
        lock.unlock()
        ack?(.failure(error))
        ready?(.failure(error))
        sensor?(.failure(error))
    }

    /// Drop pending handlers WITHOUT firing them. Use when starting a new
    /// flow on a known-clean state — e.g. `beginManualSync` for the BLE
    /// manual-sync path. Firing stale completions would trigger their
    /// captured side effects (a stale `discardSession` completion from a
    /// previous Stop calls `btManager.disconnect(...)` and tears down the
    /// freshly re-established BLE link mid-0x16 write).
    func clearAllSilently() {
        lock.lock()
        ackHandler = nil
        readyHandler = nil
        sensorInfoHandler = nil
        lock.unlock()
    }

    func handleNotification(_ data: Data) {
        guard let frame = V2BinaryProtocol.decodeResponse(data) else {
            Log.warning("V2 response decode failed: raw=\(data as NSData)")
            return
        }
        dispatch(frame)
    }

    private func dispatch(_ frame: V2BinaryProtocol.ResponseFrame) {
        switch frame {
        case .ack:
            Log.info("V2 response: Ack")
            lock.lock()
            let h = ackHandler; ackHandler = nil
            lock.unlock()
            h?(.success(()))
        case .ready:
            lock.lock()
            let alreadyConsumed = firstReadyConsumedStorage
            firstReadyConsumedStorage = true
            let h = readyHandler; readyHandler = nil
            lock.unlock()
            Log.info("V2 response: Ready (firstReadyConsumed=\(alreadyConsumed))")
            // First Ready completes a Setup-class command (NewSessionConfig /
            // ContinueSession / DiscardSession). Subsequent Readys are heartbeats —
            // forward to any installed handler, otherwise no-op.
            h?(.success(()))
        case .nack(let err, let raw):
            Log.error("V2 response: Nack(0x\(String(raw, radix: 16)))")
            let dispatchError = DispatchError.nack(err, raw: raw)
            lock.lock()
            let ack = ackHandler; ackHandler = nil
            let ready = readyHandler; readyHandler = nil
            lock.unlock()
            ack?(.failure(dispatchError))
            ready?(.failure(dispatchError))
        case .sensorInfo(let info):
            Log.info("V2 response: SensorInfo \"\(info)\"")
            lock.lock()
            let h = sensorInfoHandler; sensorInfoHandler = nil
            lock.unlock()
            h?(.success(info))
        case .syncInfo:
            Log.info("V2 response: SyncInfo (Phase 2 ignores; deferred to StartSync flow)")
        case .unknown(let byte):
            Log.warning("V2 response: unknown opcode 0x\(String(byte, radix: 16))")
        }
    }
}
