// Created by Lunar on 30/04/2026.
//

import Foundation
import CoreBluetooth

enum V2BinaryProtocol {
    enum ServiceUUID {
        static let v2 = CBUUID(string: "a0e1f000-0001-4b3c-8e9a-1f2d3c4b5a60")
    }

    enum CharacteristicUUIDs {
        static let status      = CBUUID(string: "a0e1f000-0002-4b3c-8e9a-1f2d3c4b5a60")
        static let command     = CBUUID(string: "a0e1f000-0003-4b3c-8e9a-1f2d3c4b5a60")
        static let response    = CBUUID(string: "a0e1f000-0004-4b3c-8e9a-1f2d3c4b5a60")
        static let measurement = CBUUID(string: "a0e1f000-0005-4b3c-8e9a-1f2d3c4b5a60")
        static let sync        = CBUUID(string: "a0e1f000-0006-4b3c-8e9a-1f2d3c4b5a60")

        static let notifying: [CBUUID] = [status, response, measurement, sync]
        static let all: [CBUUID] = [status, command, response, measurement, sync]
    }

    enum OpCode: UInt8 {
        case continueSession  = 0x10
        case discardSession   = 0x11
        case startSync        = 0x12
        case newSessionConfig = 0x13
        case getSensors       = 0x14
        case setTime          = 0x15
        case startBleSync     = 0x16
    }

    enum ResponseCode: UInt8 {
        case ack        = 0x20
        case nack       = 0x21
        case ready      = 0x22
        case sensorInfo = 0x23
        case syncInfo   = 0x24
    }

    enum NackError: UInt8 {
        case noSession                = 0x01
        case invalidConfig            = 0x02
        case storageHasMeasurements   = 0x03
        case clearOrSyncStorageFailed = 0x04
        case invalidWifiCredentials   = 0x05
        case syncFailed               = 0x06
    }

    enum StatusCode: UInt8 {
        case idle             = 0x00
        case hasSavedSession  = 0x01
        case running          = 0x02
        case readyToSync      = 0x03
    }

    static let settleDelaySeconds: TimeInterval = 0.3
    static let statusFallbackReadDelaySeconds: TimeInterval = 1.0

    static let mobileIntervalSeconds: UInt16 = 1
    static let fixedIntervalSeconds: UInt16 = 60

    enum SessionMode: UInt8 {
        case fixed  = 0x00
        case mobile = 0x01
    }

    static func buildDiscardSession() -> Data {
        Data([OpCode.discardSession.rawValue])
    }

    static func buildContinueSession() -> Data {
        Data([OpCode.continueSession.rawValue])
    }

    static func buildGetSensors() -> Data {
        Data([OpCode.getSensors.rawValue])
    }

    static func buildStartBleSync() -> Data {
        Data([OpCode.startBleSync.rawValue])
    }

    static func buildSetTime(date: Date = Date()) -> Data {
        var bytes = Data([OpCode.setTime.rawValue])
        var seconds = Int64(date.timeIntervalSince1970).littleEndian
        withUnsafeBytes(of: &seconds) { bytes.append(contentsOf: $0) }
        return bytes
    }

    /// Mobile NewSessionConfig: 20 bytes, NO session_token.
    /// `[0x13] + UUID_LE(16) + interval=1_LE(2) + 0x01`
    static func buildNewSessionConfigMobile(uuid: UUID,
                                            interval: UInt16 = mobileIntervalSeconds) -> Data {
        var data = Data([OpCode.newSessionConfig.rawValue])
        data.append(uuid.toV2LEBytes())
        var le = interval.littleEndian
        withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        data.append(SessionMode.mobile.rawValue)
        return data
    }

    /// Fixed NewSessionConfig: 134 bytes.
    /// `[0x13] + UUID_LE(16) + interval=60_LE(2) + 0x00 + pm1_idx(1) + pm25_idx(1) +
    ///  token_LE(16) + ssid_padded(32) + password_padded(64)`
    /// Byte 19 is the mode byte (0x00 = FIXED) — order matters; the session_token
    /// comes AFTER the indices, not immediately after the UUID. The session token
    /// is delivered as a 32-char hex string from the backend (16 raw bytes big-endian);
    /// firmware reads it via `u128::from_le_bytes` so the bytes are reversed here.
    static func buildNewSessionConfigFixed(uuid: UUID,
                                           pm1Index: UInt8,
                                           pm25Index: UInt8,
                                           sessionTokenHex: String,
                                           wifiSSID: String,
                                           wifiPassword: String,
                                           interval: UInt16 = fixedIntervalSeconds) -> Data? {
        guard let tokenBytes = sessionTokenBytesLE(fromHex: sessionTokenHex) else { return nil }
        var data = Data([OpCode.newSessionConfig.rawValue])
        data.append(uuid.toV2LEBytes())
        var le = interval.littleEndian
        withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        data.append(SessionMode.fixed.rawValue)
        data.append(pm1Index)
        data.append(pm25Index)
        data.append(tokenBytes)
        data.append(padNullTerminated(wifiSSID, length: 32))
        data.append(padNullTerminated(wifiPassword, length: 64))
        return data
    }

    /// Decode the BE-hex session_token (32 hex chars = 16 bytes, big-endian MSB-first)
    /// and reverse to little-endian for the firmware's `u128::from_le_bytes`.
    static func sessionTokenBytesLE(fromHex hex: String) -> Data? {
        let trimmed = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        guard trimmed.count == 32 else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(16)
        var idx = trimmed.startIndex
        while idx < trimmed.endIndex {
            let next = trimmed.index(idx, offsetBy: 2)
            guard let byte = UInt8(trimmed[idx..<next], radix: 16) else { return nil }
            bytes.append(byte)
            idx = next
        }
        return Data(bytes.reversed())
    }

    /// UTF-8-encode `s`, truncate / null-pad to exactly `length` bytes.
    static func padNullTerminated(_ s: String, length: Int) -> Data {
        var bytes = Array(s.utf8.prefix(length))
        if bytes.count < length {
            bytes.append(contentsOf: [UInt8](repeating: 0, count: length - bytes.count))
        }
        return Data(bytes)
    }

    enum ResponseFrame: Equatable {
        case ack
        case nack(NackError, raw: UInt8)
        case ready
        case sensorInfo(String)
        case syncInfo(ssid: String, password: String)
        case unknown(UInt8)
    }

    static func decodeResponse(_ data: Data) -> ResponseFrame? {
        guard let first = data.first else { return nil }
        guard let code = ResponseCode(rawValue: first) else {
            return .unknown(first)
        }
        switch code {
        case .ack: return .ack
        case .ready: return .ready
        case .nack:
            guard data.count >= 2 else { return .nack(.invalidConfig, raw: 0) }
            let raw = data[data.startIndex + 1]
            let mapped = NackError(rawValue: raw) ?? .invalidConfig
            return .nack(mapped, raw: raw)
        case .sensorInfo:
            let payload = data.dropFirst()
            let str = String(data: payload, encoding: .utf8) ?? ""
            return .sensorInfo(str)
        case .syncInfo:
            // 32B SSID + 64B password (null-padded)
            guard data.count >= 1 + 32 + 64 else { return nil }
            let ssidEnd = data.startIndex + 1 + 32
            let pwdEnd  = ssidEnd + 64
            let ssidBytes = data.subdata(in: (data.startIndex + 1)..<ssidEnd)
            let pwdBytes  = data.subdata(in: ssidEnd..<pwdEnd)
            return .syncInfo(ssid: trimNulls(ssidBytes), password: trimNulls(pwdBytes))
        }
    }

    private static func trimNulls(_ data: Data) -> String {
        let trimmed = data.prefix { $0 != 0 }
        return String(data: trimmed, encoding: .utf8) ?? ""
    }

    enum Status: Equatable {
        case idle(battery: BatteryReading)
        case hasSavedSession(battery: BatteryReading, sessionUUID: UUID, hasMeasurements: Bool, fileSize: UInt64?)
        case running(battery: BatteryReading, sessionUUID: UUID)
        case readyToSync(fileSize: UInt64)

        var sessionUUID: UUID? {
            switch self {
            case .idle, .readyToSync: return nil
            case .hasSavedSession(_, let uuid, _, _): return uuid
            case .running(_, let uuid): return uuid
            }
        }

        var fileSize: UInt64? {
            switch self {
            case .hasSavedSession(_, _, _, let size): return size
            case .readyToSync(let size): return size
            case .idle, .running: return nil
            }
        }
    }

    struct BatteryReading: Equatable {
        let percentage: Int
        let isCharging: Bool
    }

    enum DecodeError: Error {
        case empty
        case unknownStatusCode(UInt8)
        case truncated
    }

    static func decodeBattery(_ raw: UInt8) -> BatteryReading {
        let signed = Int8(bitPattern: raw)
        return BatteryReading(percentage: abs(Int(signed)), isCharging: signed >= 0)
    }

    static func decodeStatus(_ data: Data) -> Result<Status, DecodeError> {
        guard let first = data.first else { return .failure(.empty) }
        guard let code = StatusCode(rawValue: first) else {
            return .failure(.unknownStatusCode(first))
        }
        // ReadyToSync (0x03) has no battery byte at offset 1 — short-circuit before the
        // generic battery decoder (FW commit `ed751b180`). Payload = [0x03, file_size_u64_LE, ...password].
        if code == .readyToSync {
            guard data.count >= 1 + 8 else { return .failure(.truncated) }
            let size = readU64LE(data, at: data.startIndex + 1)
            return .success(.readyToSync(fileSize: size))
        }
        guard data.count >= 2 else { return .failure(.truncated) }
        let battery = decodeBattery(data[data.startIndex + 1])

        switch code {
        case .idle:
            return .success(.idle(battery: battery))
        case .running:
            guard data.count >= 2 + 16,
                  let uuid = UUID.fromV2LEBytes(data.subdata(in: (data.startIndex + 2)..<(data.startIndex + 18)))
            else { return .failure(.truncated) }
            return .success(.running(battery: battery, sessionUUID: uuid))
        case .hasSavedSession:
            // 27-byte payload: [opcode, battery, uuid_16B, has_measurements, file_size_u64_LE] (FW commit `3990cf22`).
            // Older firmware emits 19 bytes without file_size — accept either.
            guard data.count >= 2 + 16 + 1,
                  let uuid = UUID.fromV2LEBytes(data.subdata(in: (data.startIndex + 2)..<(data.startIndex + 18)))
            else { return .failure(.truncated) }
            let hasMeasurements = data[data.startIndex + 18] != 0
            let fileSize: UInt64?
            if data.count >= 2 + 16 + 1 + 8 {
                fileSize = readU64LE(data, at: data.startIndex + 19)
            } else {
                fileSize = nil
            }
            return .success(.hasSavedSession(battery: battery,
                                             sessionUUID: uuid,
                                             hasMeasurements: hasMeasurements,
                                             fileSize: fileSize))
        case .readyToSync:
            return .failure(.truncated) // handled above
        }
    }

    private static func readU64LE(_ data: Data, at index: Data.Index) -> UInt64 {
        var value: UInt64 = 0
        for i in 0..<8 {
            value |= UInt64(data[index + i]) << (8 * i)
        }
        return value
    }

    /// Crude ETA estimator for the StartBleSync (0x16) flow. `bytesPerSecond` is a
    /// hand-calibrated throughput baseline; Android uses ~1700 B/s — iOS BLE
    /// throughput is similar in practice. Returns ≥ 1 s.
    static let bleSyncBytesPerSecond: Double = 1700
    static func estimateSyncSeconds(fileSize: UInt64?) -> Int {
        guard let size = fileSize, size > 0 else { return 1 }
        let seconds = Double(size) / bleSyncBytesPerSecond
        return max(1, Int(seconds.rounded(.up)))
    }
}

extension UUID {
    func toV2LEBytes() -> Data {
        let u = self.uuid
        let std: [UInt8] = [u.0, u.1, u.2, u.3, u.4, u.5, u.6, u.7,
                            u.8, u.9, u.10, u.11, u.12, u.13, u.14, u.15]
        var bytes = Data(count: 16)
        bytes[0..<4]  = Data(std[0..<4].reversed())
        bytes[4..<6]  = Data(std[4..<6].reversed())
        bytes[6..<8]  = Data(std[6..<8].reversed())
        bytes[8..<16] = Data(std[8..<16])
        return bytes
    }

    static func fromV2LEBytes(_ data: Data) -> UUID? {
        guard data.count == 16 else { return nil }
        let b = [UInt8](data)
        let std: [UInt8] = [
            b[3], b[2], b[1], b[0],
            b[5], b[4],
            b[7], b[6],
            b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]
        ]
        let tuple: uuid_t = (std[0], std[1], std[2], std[3],
                             std[4], std[5], std[6], std[7],
                             std[8], std[9], std[10], std[11],
                             std[12], std[13], std[14], std[15])
        return UUID(uuid: tuple)
    }
}
