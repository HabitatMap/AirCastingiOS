// Created by Lunar on 24/11/2021.
//

import Foundation

enum SDCardValidationError: Error {
    case insufficientIntegrity
}

protocol SDSyncFileValidator {
    func validate(files: [(URL, SDCardSessionType, expectedMeasurementsCount: Int)], completion: (Result<Void, SDCardValidationError>) -> Void)
}

struct SDSyncFileValidationService: SDSyncFileValidator {
    func validate(files: [(URL, SDCardSessionType, expectedMeasurementsCount: Int)], completion: (Result<Void, SDCardValidationError>) -> Void) {
        files.forEach { file in
            if !check(file) {
                completion(.failure(SDCardValidationError.insufficientIntegrity))
                return
            }
        }
        completion(.success(()))
    }
    
    func check(_ file: (URL, SDCardSessionType, expectedMeasurementsCount: Int)) -> Bool {
        do {
            let fileHandle = try FileHandle(forReadingFrom: file.0)
        } catch {
            return false
        }
        
        //TODO: Implement checking in files has the right number of rows and if rows have right amount of values
        
        return true
    }
}
