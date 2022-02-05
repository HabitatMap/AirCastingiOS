import Foundation
import UIKit
import Resolver

extension DocumentsFileLoggerStore {
    class LogHandle: FileLoggerFileHandle {
        let filePath: URL
        private let headerLineCount: UInt
        private let maxBufferSize = 25
        private let maxLogs: UInt
        private let overflowThreshold: UInt
        private var willTerminateToken: Any?
        
        private var buffer: [String] = []
        private var logCounter: UInt = 0
        private let trimmer: TextFileTrimmer
        
        init(filePath: URL, headerLineCount: UInt, maxLogs: UInt, overflowThreshold: UInt) throws {
            assert(maxLogs + overflowThreshold > maxBufferSize, "Max logs cannot be lower than max buffer size!")
            self.filePath = filePath
            self.headerLineCount = headerLineCount
            self.maxLogs = maxLogs
            self.overflowThreshold = overflowThreshold
            let reader = Resolver.resolve(FileLineReader.self)
            self.trimmer = TextFileTrimmer(reader: reader)
            
            try countInitialLogSize(with: reader)
            prepareForAppTermination()
        }
        
        func appendFile(with message: String) throws {
            logCounter += 1
            buffer.append(message)
            if buffer.count == maxBufferSize {
                try saveBufferContents()
            }
        }
        
        func saveBufferContents() throws {
            guard buffer.count > 0 else { return }
            let systemHandle = try FileHandle(forWritingTo: filePath)
            try systemHandle.seekToEnd()
            let data = ("\n"+buffer.joined(separator: "\n")).data(using: .utf8)!
            try systemHandle.write(contentsOf: data)
            try systemHandle.synchronize()
            try systemHandle.close()
            buffer = []
            try performFileTrimming()
        }
        
        private func performFileTrimming() throws {
            guard logCounter > maxLogs + overflowThreshold else { return }
            let logsToTrim = logCounter - maxLogs
            try trimmer.trim(at: filePath, direction: .beginning(offset: headerLineCount), trimCount: logsToTrim)
            logCounter = maxLogs
        }
        
        private func prepareForAppTermination() {
            willTerminateToken = NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { [weak self] _ in
                try? self?.saveBufferContents()
            }
        }
        
        private func countInitialLogSize(with reader: FileLineReader) throws {
            try reader.readLines(of: filePath) { progress in
                guard case .line(_) = progress else { return }
                logCounter += 1
            }
            logCounter -= headerLineCount
        }
        
        deinit {
            try? saveBufferContents()
        }
    }
}
