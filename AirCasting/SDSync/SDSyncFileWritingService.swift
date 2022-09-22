// Created by Lunar on 18/11/2021.
//

import Foundation

protocol SDSyncFileWriter {
    func writeToFile(data: String, sessionType: SDCardSessionType)
    func finishAndSave() -> [(URL, SDCardSessionType)]
    func finishAndRemoveFiles()
}

final class SDSyncFileWritingService: SDSyncFileWriter {
//    var mobileFileURL: URL?
//    var fixedFileURL: URL?
    
    private var path: URL {
        FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
    }
    
    private let bufferThreshold: Int
    // We add buffers to limit the amount of savings to file. We save to file only when the amount of data reaches the threshold, or when the flushAndSave() func is called.
    private var buffers: [URL: [String]] = [:]
    private var fileHandles: [URL: FileHandle] = [:]
    private let parser = SDCardMeasurementsParser()
    private var currentURL: URL? {
        didSet {
            guard currentURL != oldValue, let oldValue else { return }
            Log.debug("## New session, flashing buffer")
            flushBuffer(for: oldValue)
        }
    }
    
    init(bufferThreshold: Int) {
        self.bufferThreshold = bufferThreshold
    }
    
    func writeToFile(data: String, sessionType: SDCardSessionType) {
        if fileHandles.count == 0 {
            do {
                try createDirectories()
            } catch {
                Log.error("Error creating directories! \(error.localizedDescription)")
                return
            }
        }
        
        let lines = data.components(separatedBy: "\r\n").filter { !$0.trimmingCharacters(in: ["\n"]).isEmpty }
        Log.debug("## \(data)")
        
        lines.forEach { line in
            guard let uuid = parser.getUUID(lineString: line) else { return }
            let url = fileURL(for: sessionType, with: uuid)
            currentURL = url
            buffers[url, default: []].append(line)
            let bufferCount = buffers[url]?.count ?? 0
            guard bufferCount == bufferThreshold else { return }
            flushBuffer(for: url)
        }
    }
    
    func finishAndSave() -> [(URL, SDCardSessionType)] {
        guard fileHandles.count > 0 else {
            do {
                try removeFiles()
            } catch {
                Log.error("Error while removing files! \(error.localizedDescription)")
                return []
            }
            return []
        }
        
        let toReturn = [(directoryURL(for: .mobile), SDCardSessionType.mobile), (directoryURL(for: .fixed), SDCardSessionType.fixed)]
        flushBuffers()
        do {
            try closeFiles()
        } catch {
            Log.error("Error closing files! \(error.localizedDescription)")
        }
        return toReturn
    }
    
    func finishAndRemoveFiles() {
        buffers = [:]
        do {
            try closeFiles()
            try removeFiles()
        } catch {
            Log.error("Error finishing! \(error.localizedDescription)")
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
            Log.debug("## Removed files")
        }
    }
    
    private func flushBuffer(for url: URL) {
        Log.debug("## Flashing buffer")
        do {
            let file = try getFileHandle(for: url)
            try file.seekToEnd()
            guard let buffer = buffers[url] else { return }
            let content = buffer.joined(separator: "\n") + "\n"
            guard let data = content.data(using: .utf8) else { return }
            try file.write(contentsOf: data)
        } catch {
            Log.error("Writing to file failed: \(error)")
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
            Log.error("Unexpected file found at \(fileURL)")
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
