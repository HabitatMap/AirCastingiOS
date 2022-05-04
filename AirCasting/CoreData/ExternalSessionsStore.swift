// Created by Lunar on 26/04/2022.
//

import Foundation
import CoreData

protocol ExternalSessionsStore {
    func createExternalSession(session: ExternalSessionWithStreamsAndMeasurements) throws
    func getExistingSession(uuid: String) throws -> ExternalSessionEntity
}

struct DefaultExternalSessionsStore: ExternalSessionsStore {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func createExternalSession(session: ExternalSessionWithStreamsAndMeasurements) throws {
        // Check if session with this uuid doesn't already exist in the db
        let sessionEntity = newSessionEntity()
        updateSessionsParams(sessionEntity, session: session)
        session.streams.forEach { stream in
            addStream(stream, to: sessionEntity)
        }
        
        // TODO: If thresholds don't exist in the db already, create the thresholdsEntity
        
        try context.save()
    }
    
    private func addStream(_ stream: ExternalSessionWithStreamsAndMeasurements.Stream, to session: ExternalSessionEntity) {
        let measurementStream = MeasurementStreamEntity(context: context)
        updateMeasurementStreamParams(measurementStream, stream: stream, session: session)
        session.addToMeasurementStreams(measurementStream)
    }
    
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
    
    private func updateSessionsParams(_ entity: ExternalSessionEntity, session: ExternalSessionWithStreamsAndMeasurements) {
        entity.uuid = session.uuid
        entity.name = session.name
        entity.latitude = session.latitude
        entity.longitude = session.longitude
        entity.startTime = session.startTime
        entity.endTime = session.endTime
        entity.provider = session.provider
    }
    
    private func updateMeasurementStreamParams(_ entity: MeasurementStreamEntity, stream: ExternalSessionWithStreamsAndMeasurements.Stream, session: ExternalSessionEntity) {
        let newStream = MeasurementStreamEntity(context: context)
        newStream.sensorName = stream.sensorName
        newStream.sensorPackageName = stream.sensorPackageName
        newStream.measurementType = stream.measurementType
        newStream.measurementShortType = stream.measurementShortType
        newStream.unitName = stream.unitName
        newStream.unitSymbol = stream.unitSymbol
        newStream.thresholdVeryLow = stream.thresholdsValues.veryLow
        newStream.thresholdLow = stream.thresholdsValues.low
        newStream.thresholdMedium = stream.thresholdsValues.medium
        newStream.thresholdHigh = stream.thresholdsValues.high
        newStream.thresholdVeryHigh = stream.thresholdsValues.veryHigh
        newStream.gotDeleted = false
    }
}
