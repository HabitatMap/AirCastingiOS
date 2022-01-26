// Created by Lunar on 25/06/2021.
//

import Foundation
@testable import AirCasting

extension SessionsSynchronization.SynchronizationContext {
    static var empty: Self { .init(needToBeDownloaded: [], needToBeUploaded: [], removed: []) }
}

extension SessionsSynchronization.SessionDownstreamData {
    static func mock(uuid: SessionUUID = .random, latitude: Double = .default, longitude: Double = .default) -> Self {
        .init(id: .default,
              createdAt: .distantPast,
              updatedAt: .distantPast.advanced(by: 3600),
              userId: .default,
              urlToken: .default,
              type: .default,
              uuid: uuid,
              title: .default,
              tagList: .default,
              startTime: .distantPast,
              endTime: .distantFuture,
              latitude: latitude,
              longitude: longitude,
              contribute: .default,
              version: .default,
              streams: .default,
              location: .default,
              isIndoor: .default,
              notes: [])
    }
}

extension SessionsSynchronization.SessionStoreSessionData {
    static func mock(uuid: String = "1234-5678") -> Self {
        .init(uuid: .init(rawValue: uuid)!,
              contribute: true,
              endTime: .distantFuture,
              gotDeleted: false,
              isIndoor: false,
              name: "Coolio",
              startTime: .distantPast,
              tags: "NOTAG",
              urlLocation: "http://www.google.com",
              version: 1,
              longitude: 51.0,
              latitude: 51.0,
              sessionType: SessionType.mobile.rawValue,
              measurementStreams: [
                SessionsSynchronization.SessionStoreMeasurementStreamData(id: 54321,
                                                                               measurementShortType: "dB",
                                                                               measurementType: "Sound Level",
                                                                               sensorName: "Phone Microphone",
                                                                               sensorPackageName: "Builtin",
                                                                               thresholdHigh: 80,
                                                                               thresholdLow: 60,
                                                                               thresholdMedium: 70,
                                                                               thresholdVeryHigh: 100,
                                                                               thresholdVeryLow: 20,
                                                                               unitName: "decibels",
                                                                               unitSymbol: "dB",
                                                                               deleted: false,
                                                                               measurements: [
                                                                                .init(id: 1234,
                                                                                      time: DateBuilder.getDateWithTimeIntervalSinceReferenceDate(_ timeInterval: 150),
                                                                                      value: 12.02,
                                                                                      latitude: 51.04,
                                                                                      longitude: 50.12)
                                                                               ])
              ],
              deleted: false,
              notes: [])
    }
}

extension SessionUUID {
    static var random: SessionUUID {
        return .init(rawValue: UUID().uuidString)!
    }
}

extension SessionsSynchronization.MeasurementStreamDownstreamData: TestDefaultProviding {
    static var `default`: SessionsSynchronization.MeasurementStreamDownstreamData {
        .mock()
    }
}

extension SessionsSynchronization.SessionDownstreamData: TestDefaultProviding {
    static var `default`: SessionsSynchronization.SessionDownstreamData {
        .mock(uuid: .random)
    }
}

extension SessionsSynchronization.SessionStoreSessionData: TestDefaultProviding {
    static var `default`: SessionsSynchronization.SessionStoreSessionData {
        .mock()
    }
}

extension SessionsSynchronization.MeasurementStreamDownstreamData {
    static func mock() -> Self {
        .init(id: 54321,
              sensorName: "Phone Microphone",
              sensorPackageName: "Builtin",
              unitName: "decibels",
              measurementType: "Sound Level",
              measurementShortType: "dB",
              unitSymbol: "dB",
              thresholdVeryLow: 20,
              thresholdLow: 60,
              thresholdMedium: 70,
              thresholdHigh: 80,
              thresholdVeryHigh: 100,
              size: 11,
              measurements: [])
    }
}

// MARK: Conveniance extensions

extension Array where Element == SessionStoreMock.HistoryItem {
    var allReads: [Element] { filter { if case .readSession(_) = $0 { return true }; return false } }
    var allWrites: [Element] { filter { if case .addSessions(_) = $0 { return true }; return false } }
    var allDeletes: [Element] { filter { if case .removeSessions(_) = $0 { return true }; return false } }
    
    var allWrittenData: [SessionsSynchronization.SessionStoreSessionData] {
        allWrites.map { write -> [SessionsSynchronization.SessionStoreSessionData]? in
            guard case .addSessions(let session) = write else { return nil }
            return session
        }
        .compactMap { $0 }
        .flatMap { $0 }
    }
    
    var allWrittenUUIDs: [SessionUUID] { allWrittenData.map(\.uuid) }
    
    var allRemovedUUIDs: [SessionUUID] {
        allDeletes.map { item -> [SessionUUID]? in
            guard case .removeSessions(let uuids) = item else { return nil }
            return uuids
        }
        .compactMap { $0 }
        .flatMap { $0 }
    }
}

extension Array where Element == SessionsSynchronization.SessionStoreSessionData {
    var uuids: [SessionUUID] { map(\.uuid) }
}

extension Array where Element == SessionsSynchronization.SessionUpstreamData {
    var uuids: [SessionUUID] { map(\.uuid) }
}
