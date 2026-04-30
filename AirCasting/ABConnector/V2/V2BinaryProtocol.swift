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
    }

    enum StatusCode: UInt8 {
        case idle             = 0x00
        case hasSavedSession  = 0x01
        case running          = 0x02
    }

    static let settleDelaySeconds: TimeInterval = 0.3
    static let statusFallbackReadDelaySeconds: TimeInterval = 1.0

    enum Status: Equatable {
        case idle(battery: BatteryReading)
        case hasSavedSession(battery: BatteryReading, sessionUUID: UUID, hasMeasurements: Bool)
        case running(battery: BatteryReading, sessionUUID: UUID)
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
        guard data.count >= 2 else { return .failure(.truncated) }
        let battery = decodeBattery(data[data.startIndex + 1])

        guard let code = StatusCode(rawValue: first) else {
            return .failure(.unknownStatusCode(first))
        }
        switch code {
        case .idle:
            return .success(.idle(battery: battery))
        case .running:
            guard data.count >= 2 + 16,
                  let uuid = UUID.fromV2LEBytes(data.subdata(in: (data.startIndex + 2)..<(data.startIndex + 18)))
            else { return .failure(.truncated) }
            return .success(.running(battery: battery, sessionUUID: uuid))
        case .hasSavedSession:
            guard data.count >= 2 + 16 + 1,
                  let uuid = UUID.fromV2LEBytes(data.subdata(in: (data.startIndex + 2)..<(data.startIndex + 18)))
            else { return .failure(.truncated) }
            let hasMeasurements = data[data.startIndex + 18] != 0
            return .success(.hasSavedSession(battery: battery,
                                             sessionUUID: uuid,
                                             hasMeasurements: hasMeasurements))
        }
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
