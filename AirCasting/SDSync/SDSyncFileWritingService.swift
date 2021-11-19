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
    
    private var buffers: [SDCardSessionType: [String]] = [:]
    private var files: [SDCardSessionType: FileHandle] = [:]
    
    func finishAndSave() {
        flushBuffers()
        do {
            try closeFiles()
        } catch {
            Log.error("Error closing files! \(error.localizedDescription)")
        }
        
        SDCardSessionType.allCases.forEach { sessionType in
            Log.info("\(try! String(contentsOfFile: fileURL(for: sessionType).path)) \(fileURL(for: sessionType).path)")
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
        
        let dataEntries = data.components(separatedBy: "\r\n").filter { !$0.trimmingCharacters(in: ["\n"]).isEmpty }
        var buffer = buffers[sessionType, default: []]
        defer { buffers[sessionType] = buffer }
        guard buffer.count > 20 else {
            buffer.append(contentsOf: dataEntries)
            return
        }
        
        flushBuffer(for: sessionType)
    }
    
    private func flushBuffers() {
        SDCardSessionType.allCases.forEach { flushBuffer(for: $0) }
    }
    
    private func openFiles() throws {
        try SDCardSessionType.allCases.forEach {
            files[$0] = try FileHandle(forWritingTo: fileURL(for: $0))
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
        var buffer = buffers[sessionType, default: []]
        defer { buffers[sessionType] = buffer }
        do {
            guard let file = files[sessionType] else {
                Log.warning("File handle not found for session type \(sessionType)")
                return
            }
            try file.seekToEnd()
            try file.write(contentsOf: buffer.joined(separator: "\n").data(using: .utf8) ?? Data())
        } catch {
            Log.error("Writing to file failed: \(error)")
        }
        buffer = []
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
