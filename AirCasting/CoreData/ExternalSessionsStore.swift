// Created by Lunar on 26/04/2022.
//

import Foundation
import CoreData

protocol ExternalSessionsStore {
    func createExternalSession(session: PartialExternalSession) throws
    func getExistingSession(uuid: String) throws -> ExternalSessionEntity
}

struct DefaultExternalSessionsStore: ExternalSessionsStore {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func createExternalSession(session: PartialExternalSession) throws {
        let sessionEntity = newSessionEntity()
        updateSessionsParams(sessionEntity, session: session)
        try context.save()
    }
    
//    func addStream(_ stream: ExternalSessionStream, to sessionUUID: String) throws {
//        let existingSession = try context.existingExternalSession(uuid: sessionUUID)
//        let measurementStream = MeasurementStreamEntity(context: context)
//
//    }
    
    // THIS IS FOR DEBUGGING PURPOSES
    func getExistingSession(uuid: String) throws -> ExternalSessionEntity {
        try context.existingExternalSession(uuid: uuid)
    }
    
    private func newSessionEntity() -> ExternalSessionEntity {
        let sessionEntity = ExternalSessionEntity(context: context)
        let uiState = UIStateEntity(context: context)
        uiState.externalSession = sessionEntity
        return sessionEntity
    }
    
    private func updateSessionsParams(_ entity: ExternalSessionEntity, session: PartialExternalSession) {
        entity.uuid = session.uuid
        entity.name = session.name
        entity.latitude = session.latitude
        entity.longitude = session.longitude
        entity.startTime = session.startTime
        entity.endTime = session.endTime
        entity.provider = session.provider
    }
    
//    private func updateMeasurementStreamParams(_ entity: MeasurementStreamEntity, stream: ExternalSessionStream, session: ExternalSessionEntity) {
//        let newStream = MeasurementStreamEntity(context: context)
//        newStream.sensorName = stream.sensorName
//        newStream.sensorPackageName = stream.sensorPackageName
//        newStream.measurementType = stream.measurementType
//        newStream.measurementShortType = stream.measurementShortType
//        newStream.unitName = stream.unitName
//        newStream.unitSymbol = stream.unitSymbol
//        newStream.thresholdVeryLow = stream.thresholds.veryLow
//        newStream.thresholdLow = stream.thresholds.low
//        newStream.thresholdMedium = stream.thresholds.medium
//        newStream.thresholdHigh = stream.thresholds.high
//        newStream.thresholdVeryHigh = stream.thresholds.veryHigh
//        newStream.gotDeleted = false
//
//        session.addToMeasurementStreams(newStream)
//    }
}
