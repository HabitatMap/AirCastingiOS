// Created by Lunar on 24/11/2021.
//

import Foundation
import Resolver

enum SDCardValidationError: Error {
    case insufficientIntegrity
}

protocol SDSyncFileValidator {
    func validate(files: [SDCardCSVFile], completion: (Result<Void, SDCardValidationError>) -> Void)
}

struct SDSyncFileValidationService: SDSyncFileValidator {
    private let expectedFieldsCount: Int
    private let acceptanceThreshold = 0.8
    
    @Injected private var fileLineReader: FileLineReader
    
    init(type: AirBeamDeviceType) {
        switch type {
            //TODO: ask Mike - should we remove this?
        case .airBeam2, .airBeam3:
            expectedFieldsCount = 13
        case .airBeamMini:
            expectedFieldsCount = 4
        }
    }
    
    func validate(files: [SDCardCSVFile], completion: (Result<Void, SDCardValidationError>) -> Void) {
        var result = true
        
        for file in files {
            if !check(file) {
                Log.info("[SD Sync] Check failed for directory \(file)")
                result = false
                break
            }
        }
        Log.info("[SD Sync] Files validated")
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
            try self.provideLines(url: file.url, progress: { line in
                switch line {
                case .line(let content):
                    if (lineIsCorrupted(content)) {
                        Log.info("[SD Sync] Line corrupted: \(content)")
                        corruptedCount += 1
                    }
                    allCount += 1
                case .endOfFile:
                    Log.info("[SD Sync] Reached end of csv file")
                }
            })
            
            return Stats(allCount, corruptedCount)
        } catch {
            Log.error(error.localizedDescription)
            return nil
        }
    }
    
    private func provideLines(url: URL, progress: (FileLineReaderProgress) -> Void) throws {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { progress(.endOfFile); return }
        guard isDirectory.boolValue else { try self.fileLineReader.readLines(of: url, progress: progress); return }
        let files = try FileManager.default.contentsOfDirectory(atPath: url.path).compactMap({ url.path + "/" + $0 }).compactMap(URL.init(string:))
        Log.info("Files: \(files)")
        try files.forEach { file in
            Log.info("Reading file: \(file)")
            try self.fileLineReader.readLines(of: file, progress: { line in
                switch line {
                case .line(let content):
                    progress(.line(content))
                case .endOfFile:
                    break
                }
            })
        }
        progress(.endOfFile)
    }
    
    private func lineIsCorrupted(_ line: String) -> Bool {
        let fields = line.split(separator: ",")
        return !line.isEmpty && fields.count != expectedFieldsCount && fields.count != 1
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
