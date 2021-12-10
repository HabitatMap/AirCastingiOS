// Created by Lunar on 24/11/2021.
//

import Foundation

enum SDCardValidationError: Error {
    case insufficientIntegrity
}

protocol SDSyncFileValidator {
    func validate(files: [SDCardCSVFile], completion: (Result<Void, SDCardValidationError>) -> Void)
}

struct SDSyncFileValidationService: SDSyncFileValidator {
    private let expectedFieldsCount = 13
    private let acceptanceThreshold = 0.8
    
    private let fileLineReader: FileLineReader
    
    init(fileLineReader: FileLineReader) {
        self.fileLineReader = fileLineReader
    }
    
    func validate(files: [SDCardCSVFile], completion: (Result<Void, SDCardValidationError>) -> Void) {
        var result = true
        
        for file in files {
            if !check(file) {
                result = false
                break
            }
        }
        Log.info("Files validated")
        result ? completion(.success(())) : completion(.failure(SDCardValidationError.insufficientIntegrity))
    }
    
    private func check(_ file: SDCardCSVFile) -> Bool {
        guard let stats = calculateStats(file) else {
            return false
        }
        return validateAcceptedCorruption(stats, file.expectedLinesCount)
    }
    
    private func calculateStats(_ file: SDCardCSVFile) -> Stats? {
        var allCount = 0
        var corruptedCount = 0
        do {
            try self.fileLineReader.readLines(of: file.url, progress: { line in
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
            
            return Stats(allCount, corruptedCount)
        } catch {
            Log.error(error.localizedDescription)
            return nil
        }
    }
    
    private func lineIsCorrupted(_ line: String) -> Bool {
        let fields = line.split(separator: ",")
        return !line.isEmpty && fields.count != expectedFieldsCount
    }
    
    private func validateAcceptedCorruption(_ stats: Stats, _ expectedCount: Int) -> Bool {
        if (expectedCount == 0) { return true }
        
        let countThreshold = Double(expectedCount) * acceptanceThreshold
        let corruptionThreshold = Double(expectedCount) * (1 - acceptanceThreshold)
        
        // checks if downloaded file has at least 80% of expected lines
        // and if there is at most 20% of corrupted lines
        return Double(stats.allCount) >= countThreshold && Double(stats.corruptedCount) < corruptionThreshold
    }
}

fileprivate struct Stats {
    var allCount: Int
    var corruptedCount: Int
    
    init(_ allCount: Int, _ corruptedCount: Int) {
        self.allCount = allCount
        self.corruptedCount = corruptedCount
    }
}
