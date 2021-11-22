// Created by Lunar on 18/11/2021.
//

import Foundation

protocol SDSyncFileWriter {
    mutating func writeToFile(data: String, sessionType: SDCardSessionType)
    func finishAndSave()
    func finishAndRemoveFiles()
}

final class SDSyncFileWritingService: SDSyncFileWriter {
    var mobileFileURL: URL?
    var fixedFileURL: URL?
    
    var path: URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
        return path
    }
    
    private let bufferThreshold: Int
    private var buffers: [URL: [String]] = [:]
    private var files: [URL: FileHandle] = [:]
    
    init(bufferThreshold: Int) {
        self.bufferThreshold = bufferThreshold
    }
    
    func finishAndSave() {
        flushBuffers()
        do {
            try closeFiles()
        } catch {
            Log.error("Error closing files! \(error.localizedDescription)")
        }
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
    
    func writeToFile(data: String, sessionType: SDCardSessionType) {
        if files.count == 0 {
            do {
                try openFiles()
            } catch {
                Log.error("Error opening files! \(error.localizedDescription)")
                return
            }
        }
        
        let lines = data.components(separatedBy: "\r\n").filter { !$0.trimmingCharacters(in: ["\n"]).isEmpty }
        let url = fileURL(for: sessionType)
        buffers[url, default: []].append(contentsOf: lines)
        let bufferCount = buffers[url]?.count ?? 0
        guard bufferCount == bufferThreshold else { return }
        flushBuffer(for: sessionType)
    }
    
    private func flushBuffers() {
        SDCardSessionType.allCases.forEach { flushBuffer(for: $0) }
    }
    
    private func openFiles() throws {
        let fileURLs = Set(SDCardSessionType.allCases.map { fileURL(for: $0) })
        try fileURLs.forEach { fileURL in
            let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
            if fileExists {
                try FileManager.default.removeItem(at: fileURL)
            }
            try Data().write(to: fileURL)
            files[fileURL] = try FileHandle(forWritingTo: fileURL)
        }
    }
    
    private func closeFiles() throws {
        try files.values.forEach { try $0.close() }
    }
    
    private func removeFiles() throws {
        try SDCardSessionType.allCases.forEach {
            let fileURL = fileURL(for: $0)
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    private func flushBuffer(for sessionType: SDCardSessionType) {
        let url = fileURL(for: sessionType)
        guard let file = files[url] else {
            Log.warning("File handle not found for session type \(sessionType)")
            return
        }
        do {
            try file.seekToEnd()
            guard let buffer = buffers[url] else { return }
            let content = buffer.joined(separator: "\n") + "\n"
            try file.write(contentsOf: content.data(using: .utf8) ?? Data())
        } catch {
            Log.error("Writing to file failed: \(error)")
        }
        buffers[url] = []
    }
    
    private func fileURL(for sessionType: SDCardSessionType) -> URL {
        let fileURL: URL
        if sessionType == .mobile {
            fileURL = mobileFileURL ?? path.appendingPathComponent("mobile.csv")
        } else {
            fileURL = fixedFileURL ?? path.appendingPathComponent("fixed.csv")
        }
        return fileURL
    }
}
