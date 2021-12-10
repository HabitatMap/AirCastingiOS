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
    private var EXPECTED_FIELDS_COUNT = 13
    private var ACCEPTANCE_THRESHOLD = 0.8
    
    let fileLineReader: FileLineReader
    
    init(fileLineReader: FileLineReader) {
        self.fileLineReader = fileLineReader
    }
    
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
        guard let stats = calculateStats(file) else {
            return false
        }
        return validateAcceptedCorruption(stats, file.2)
    }
    
    private func calculateStats(_ file: (URL, SDCardSessionType, expectedMeasurementsCount: Int)) -> Stats? {
        var allCount = 0
        var corruptedCount = 0
        do {
            try self.fileLineReader.readLines(of: file.0, progress: { line in
                switch line {
                case .line(let content):
                    if (lineIsCorrupted(content)) {
                        corruptedCount += 1
                    }
                    
                    allCount += 1
                case .endOfFile:
                    Log.info("Reached end of csv file")
                }
            })
            
            return Stats(allCount: allCount, corruptedCount: corruptedCount)
        } catch {
            Log.error(error.localizedDescription)
            return nil
        }
    }
    
    private func lineIsCorrupted(_ line: String) -> Bool {
        let fields = line.split(separator: ",")
        return !line.isEmpty && fields.count != EXPECTED_FIELDS_COUNT
    }
    
    private func validateAcceptedCorruption(_ stats: Stats, _ expectedCount: Int) -> Bool {
        if (expectedCount == 0) { return true }
        
        let countThreshold = Double(expectedCount) * ACCEPTANCE_THRESHOLD
        let corruptionThreshold = Double(expectedCount) * (1 - ACCEPTANCE_THRESHOLD)
        
        // checks if downloaded file has at least 80% of expected lines
        // and if there is at most 20% of corrupted lines
        return Double(stats.allCount) >= countThreshold && Double(stats.corruptedCount) < corruptionThreshold
    }
}

fileprivate struct Stats {
    var allCount: Int
    var corruptedCount: Int
}
