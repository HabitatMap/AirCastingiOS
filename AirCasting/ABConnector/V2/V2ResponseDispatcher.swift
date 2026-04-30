// Created by Lunar on 30/04/2026.
//

import Foundation

/// Routes V2 Response-characteristic notifications to per-pending-command handlers.
/// One outstanding two-stage command (Ack→Ready) at a time. The dispatcher tracks
/// whether the very first `Ready` after a `NewSessionConfig`/`ContinueSession` has
/// fired so subsequent `Ready` notifications act as idempotent heartbeats only.
final class V2ResponseDispatcher {
    enum Phase { case awaitingAck, awaitingReady, idle }

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
                }
            case .malformed:
                return "AirBeam sent a malformed response."
            }
        }
    }

    private let queue = DispatchQueue(label: "ab.v2.dispatcher")

    private var ackHandler: ((Result<Void, Error>) -> Void)?
    private var readyHandler: ((Result<Void, Error>) -> Void)?
    private var sensorInfoHandler: ((Result<String, Error>) -> Void)?
    private(set) var firstReadyConsumed: Bool = false

    func resetSessionStartGuard() {
        queue.sync { firstReadyConsumed = false }
    }

    /// Wait for an Ack, then a Ready. Calls `completion` on Ready or any failure.
    func awaitAckThenReady(completion: @escaping (Result<Void, Error>) -> Void) {
        queue.sync {
            ackHandler = { [weak self] result in
                switch result {
                case .success:
                    self?.readyHandler = completion
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }
    }

    /// Wait for a single terminal Ready (e.g. DiscardSession). Forwards Nack as failure.
    func awaitReady(completion: @escaping (Result<Void, Error>) -> Void) {
        queue.sync { readyHandler = completion }
    }

    /// Wait for a SensorInfo (0x23) reply.
    func awaitSensorInfo(completion: @escaping (Result<String, Error>) -> Void) {
        queue.sync { sensorInfoHandler = completion }
    }

    /// Drop any pending handlers (used when tearing down).
    func cancelAll(_ error: Error) {
        queue.sync {
            ackHandler?(.failure(error)); ackHandler = nil
            readyHandler?(.failure(error)); readyHandler = nil
            sensorInfoHandler?(.failure(error)); sensorInfoHandler = nil
        }
    }

    func handleNotification(_ data: Data) {
        guard let frame = V2BinaryProtocol.decodeResponse(data) else {
            Log.warning("V2 response decode failed: raw=\(data as NSData)")
            return
        }
        queue.sync { dispatch(frame) }
    }

    private func dispatch(_ frame: V2BinaryProtocol.ResponseFrame) {
        switch frame {
        case .ack:
            Log.info("V2 response: Ack")
            let h = ackHandler; ackHandler = nil
            h?(.success(()))
        case .ready:
            Log.info("V2 response: Ready (firstReadyConsumed=\(self.firstReadyConsumed))")
            if !firstReadyConsumed {
                firstReadyConsumed = true
                let h = readyHandler; readyHandler = nil
                h?(.success(()))
            } else {
                // Heartbeat / sync-done — currently no-op for Phase 2 mobile.
                let h = readyHandler; readyHandler = nil
                h?(.success(()))
            }
        case .nack(let err, let raw):
            Log.error("V2 response: Nack(0x\(String(raw, radix: 16)))")
            let dispatchError = DispatchError.nack(err, raw: raw)
            let ack = ackHandler; ackHandler = nil
            let ready = readyHandler; readyHandler = nil
            ack?(.failure(dispatchError))
            ready?(.failure(dispatchError))
        case .sensorInfo(let info):
            Log.info("V2 response: SensorInfo \"\(info)\"")
            let h = sensorInfoHandler; sensorInfoHandler = nil
            h?(.success(info))
        case .syncInfo:
            Log.info("V2 response: SyncInfo (Phase 2 ignores; deferred to StartSync flow)")
        case .unknown(let byte):
            Log.warning("V2 response: unknown opcode 0x\(String(byte, radix: 16))")
        }
    }
}
