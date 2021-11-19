// Created by Lunar on 18/11/2021.
//

import Foundation

protocol SDSyncFileWriter {
    mutating func writeToFile(data: String, sessionType: SDCardSessionType)
    func finishAndSave()
    func finishAndRemoveFiles()
}

struct SDSyncFileWritingService: SDSyncFileWriter {
    var mobileFileURL: URL?
    var fixedFileURL: URL?
    
    var path: URL {
        let path = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)[0]
        return path
    }
    
    var buffers: [SDCardSessionType: [String]] = [:]
    
    func finishAndSave() {
        //
    }
    
    func finishAndRemoveFiles() {
        //
    }
    
    mutating func writeToFile(data: String, sessionType: SDCardSessionType) {
        let dataEntries = data.components(separatedBy: "\r\n").filter { !$0.trimmingCharacters(in: ["\n"]).isEmpty }
//        Log.info("## Data entries: \(dataEntries)")
        var buffer = buffers[sessionType, default: []]
        defer { buffers[sessionType] = buffer }
        guard buffer.count > 20 else {
            buffer.append(contentsOf: dataEntries)
            return
        }
        let fileURL: URL
        if sessionType == .mobile {
            fileURL = mobileFileURL ?? path.appendingPathComponent("mobile.csv")
        } else {
            fileURL = fixedFileURL ?? path.appendingPathComponent("fixed.csv")
        }
        
        do {
            try buffer.joined(separator: "\n").write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
        buffer = []
        Log.info("\(try! String(contentsOfFile: fileURL.path)) \(fileURL.path)")
        // write to file
    }
}
