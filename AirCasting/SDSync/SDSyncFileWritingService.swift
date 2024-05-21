// Created by Lunar on 18/11/2021.
//

import Foundation

final class SDSyncFileWritingService: SDSyncFileWriter {
    private var path: URL {
        FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
    }
    
    private let bufferThreshold: Int
    // We add buffers to limit the amount of savings to file. We save to file only when the amount of data reaches the threshold, or when the flushAndSave() func is called.
    private var buffers: [URL: [String]] = [:]
    private var fileHandles: [URL: FileHandle] = [:]
    private var currentURL: URL? {
        didSet {
            guard currentURL != oldValue, let oldValue else { return }
            flushBuffer(for: oldValue)
        }
    }
    
    init(bufferThreshold: Int) {
        self.bufferThreshold = bufferThreshold
    }
    
    func writeToFile(data: String, parser: SDMeasurementsParser, sessionType: SDCardSessionType) {
        if fileHandles.count == 0 {
            do {
                try createDirectories()
            } catch {
                Log.error("[SD Sync] Error creating directories! \(error.localizedDescription)")
                return
            }
        }
        
        let lines = data.components(separatedBy: "\r\n").filter { !$0.trimmingCharacters(in: ["\n"]).isEmpty }
        
        parser.enumerateSessionLines(lines: lines) { uuid, lineString in
            var url = currentURL
            
            // UUID can be nil when data comes from ABMini, in that case just keep using the current URL
            if let uuid = uuid {
                url = fileURL(for: sessionType, with: uuid)
                currentURL = url
            }
            
            guard let url else { return }
            buffers[url, default: []].append(lineString)
            let bufferCount = buffers[url]?.count ?? 0
            guard bufferCount == bufferThreshold else { return }
            flushBuffer(for: url)
        }
    }
    
    func finishAndSave() -> [(URL, SDCardSessionType)] {
        flushBuffers()
        guard fileHandles.count > 0 else {
            do {
                try removeFiles()
            } catch {
                Log.error("[SD Sync] Error while removing files! \(error.localizedDescription)")
                return []
            }
            return []
        }
        
        let toReturn = [(directoryURL(for: .mobile), SDCardSessionType.mobile), (directoryURL(for: .fixed), SDCardSessionType.fixed)]
        do {
            try closeFiles()
        } catch {
            Log.error("[SD Sync] Error closing files! \(error.localizedDescription)")
        }
        return toReturn
    }
    
    func finishAndRemoveFiles() {
        Log.info("[SD Sync] Finish and remove called")
        buffers = [:]
        do {
            try closeFiles()
            try removeFiles()
        } catch {
            Log.error("[SD Sync] Error finishing! \(error.localizedDescription)")
        }
    }
    
    private func flushBuffers() {
        buffers.keys.forEach { flushBuffer(for: $0) }
    }
    
    private func createDirectories() throws {
        let directoryURLs = Set(SDCardSessionType.allCases.map { directoryURL(for: $0) })
        try directoryURLs.forEach { directoryURL in
            let directoryExists = FileManager.default.fileExists(atPath: directoryURL.path)
            if directoryExists {
                try FileManager.default.removeItem(at: directoryURL)
            }
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: false)
        }
    }
    
    private func closeFiles() throws {
        try fileHandles.values.forEach { try $0.close() }
        fileHandles = [:]
    }
    
    private func removeFiles() throws {
        try SDCardSessionType.allCases.forEach {
            let directoryURL = directoryURL(for: $0)
            guard FileManager.default.fileExists(atPath: directoryURL.path) else { return }
            try FileManager.default.removeItem(at: directoryURL)
        }
    }
    
    private func flushBuffer(for url: URL) {
        do {
            let file = try getFileHandle(for: url)
            try file.seekToEnd()
            guard let buffer = buffers[url] else { return }
            let content = buffer.joined(separator: "\n") + "\n"
            guard let data = content.data(using: .utf8) else { return }
            try file.write(contentsOf: data)
        } catch {
            Log.error("[SD Sync] Writing to file failed: \(error)")
        }
        buffers[url] = []
    }
    
    private func getFileHandle(for url: URL) throws -> FileHandle {
        if let file = fileHandles[url] {
            return file
        }
        
        fileHandles[url] = try openFile(fileURL: url)
        return fileHandles[url]!
    }
    
    private func openFile(fileURL: URL) throws -> FileHandle {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
            Log.error("[SD Sync] Unexpected file found at \(fileURL)")
        }
        try Data().write(to: fileURL)
        return try FileHandle(forWritingTo: fileURL)
    }
    
    private func directoryURL(for sessionType: SDCardSessionType) -> URL {
        if sessionType == .mobile {
            return path.appendingPathComponent("mobile")
        } else {
            return path.appendingPathComponent("fixed")
        }
    }
    
    private func fileURL(for sessionType: SDCardSessionType, with uuid: String) -> URL {
        directoryURL(for: sessionType).appendingPathComponent("\(uuid)")
    }
}
