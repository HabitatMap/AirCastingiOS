// Created by Lunar on 30/04/2026.
//

import Foundation

struct V2LiveMeasurement: Equatable {
    let timestamp: Date
    let pm1: UInt16
    let pm25: UInt16
}

struct V2SyncRecord: Equatable {
    let timestamp: Date
    let pm1: UInt16
    let pm25: UInt16
}

enum V2MeasurementParser {
    /// 9-byte live measurement: [count_u8=1, ts_u32_LE, pm1_u16_LE, pm2_5_u16_LE]
    static func parseLive(_ data: Data) -> V2LiveMeasurement? {
        guard data.count >= 9, data[data.startIndex] == 1 else { return nil }
        let base = data.startIndex
        let ts = readU32LE(data, at: base + 1)
        let p1 = readU16LE(data, at: base + 5)
        let p25 = readU16LE(data, at: base + 7)
        return V2LiveMeasurement(timestamp: Date(timeIntervalSince1970: TimeInterval(ts)),
                                 pm1: p1, pm25: p25)
    }

    /// Sync chunk: [count_u8, padding_2B, record_0(8B), ...] each record [ts_u32_LE, pm1_u16_LE, pm2_5_u16_LE]
    static func parseSyncChunk(_ data: Data) -> [V2SyncRecord]? {
        guard let first = data.first else { return nil }
        let count = Int(first)
        let recordSize = 8
        let headerSize = 3
        guard data.count >= headerSize + count * recordSize else { return nil }
        var out: [V2SyncRecord] = []
        out.reserveCapacity(count)
        for i in 0..<count {
            let start = data.startIndex + headerSize + i * recordSize
            let ts  = readU32LE(data, at: start)
            let p1  = readU16LE(data, at: start + 4)
            let p25 = readU16LE(data, at: start + 6)
            out.append(V2SyncRecord(timestamp: Date(timeIntervalSince1970: TimeInterval(ts)),
                                    pm1: p1, pm25: p25))
        }
        return out
    }

    private static func readU32LE(_ data: Data, at index: Data.Index) -> UInt32 {
        UInt32(data[index]) |
        (UInt32(data[index + 1]) << 8) |
        (UInt32(data[index + 2]) << 16) |
        (UInt32(data[index + 3]) << 24)
    }

    private static func readU16LE(_ data: Data, at index: Data.Index) -> UInt16 {
        UInt16(data[index]) | (UInt16(data[index + 1]) << 8)
    }
}

enum V2StreamFactory {
    /// Build PM1 / PM2.5 ABMeasurementStream for live or sync values.
    static func makeStreams(pm1: Double,
                            pm25: Double,
                            packageName: String = "AirBeamMini") -> (pm1: ABMeasurementStream, pm25: ABMeasurementStream) {
        let pm1Stream = ABMeasurementStream(
            measuredValue: pm1,
            packageName: packageName,
            sensorName: MeasurementStreamSensorName.mini_pm1.rawValue,
            measurementType: "Particulate Matter",
            measurementShortType: "PM",
            unitName: "micrograms per cubic meter",
            unitSymbol: "µg/m³",
            thresholdVeryLow: 0,
            thresholdLow: 9,
            thresholdMedium: 35,
            thresholdHigh: 55,
            thresholdVeryHigh: 150
        )
        let pm25Stream = ABMeasurementStream(
            measuredValue: pm25,
            packageName: packageName,
            sensorName: MeasurementStreamSensorName.mini_pm2_5.rawValue,
            measurementType: "Particulate Matter",
            measurementShortType: "PM",
            unitName: "micrograms per cubic meter",
            unitSymbol: "µg/m³",
            thresholdVeryLow: 0,
            thresholdLow: 9,
            thresholdMedium: 35,
            thresholdHigh: 55,
            thresholdVeryHigh: 150
        )
        return (pm1Stream, pm25Stream)
    }
}
