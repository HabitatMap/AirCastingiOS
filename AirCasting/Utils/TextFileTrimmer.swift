import Foundation

class TextFileTrimmer {
    enum Direction {
        case beginning(offset: UInt)
        case end(offset: UInt)
    }
    
    private let reader: FileLineReader
    
    init(reader: FileLineReader) {
        self.reader = reader
    }
    
    func trim(at url: URL, direction: Direction, trimCount: UInt) throws {
        guard case let .beginning(offset) = direction else {
            fatalError(".end direction is not supported!")
        }
        var lineCount: UInt = 0
        
        let tempFileUrl = tempFileURL(for: url)
        let tempFile = try openTempFileForWriting(at: tempFileUrl)
        
        try self.reader.readLines(of: url) { progress in
            do {
                try handleLine(progress, file: tempFile, offset: offset, lineCount: lineCount, trimCount: trimCount)
            } catch {
                Log.warning("Couldn't move log file: \(error)")
            }
            lineCount += 1
        }
        
        try swapFiles(url, tempFileUrl)
    }
    
    private func tempFileURL(for url: URL) -> URL {
        let fileName = url.lastPathComponent + "_temp"
        return url.deletingLastPathComponent().appendingPathComponent(fileName)
    }
    
    private func openTempFileForWriting(at url: URL) throws -> FileHandle {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        return try FileHandle(forWritingTo: url)
    }
    
    private func handleLine(_ progress: FileLineReaderProgress, file: FileHandle, offset: UInt, lineCount: UInt, trimCount: UInt) throws {
        switch progress {
        case .endOfFile: break
        case .line(let str):
            let shouldAddNewline = lineCount > trimCount
            let prefix = shouldAddNewline ? "\n" : ""
            if lineCount < offset {
                try file.write(contentsOf: (prefix + str).data(using: .utf8)!)
            } else if (lineCount - offset) < trimCount {
                break
            } else {
                try file.write(contentsOf: (prefix + str).data(using: .utf8)!)
            }
            
        }
    }
    
    private func swapFiles(_ url: URL, _ tempFileUrl: URL) throws {
        _ = try FileManager.default.replaceItemAt(url, withItemAt: tempFileUrl)
    }
}
