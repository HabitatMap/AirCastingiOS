// Created by Lunar on 26/11/2021.
//

import Foundation

class DefaultFileLineReader: FileLineReader {
    private let eofMarker = -1
    
    func readLines(of fileURL: URL, progress: (FileLineReaderProgress) -> Void) throws {
        guard let file: UnsafeMutablePointer<FILE> = fopen(fileURL.path, "r") else { throw FileLineReaderError.cannotOpenFile }
        var lineRead: UnsafeMutablePointer<CChar>?
        var bufsize: Int = 0
        while getline(&lineRead, &bufsize, file) != eofMarker {
            // Let's fully maximize this for memory by putting an autorelease pool for each iteration
            // (it's already well known this class is I/O and will for sure be slow.)
            autoreleasepool {
                let lineString = String(cString: lineRead!).trimmingCharacters(in: .newlines)
                progress(.line(lineString))
            }
        }
        free(lineRead)
        fclose(file)
        progress(.endOfFile)
    }
    
    func readLastLine(of fileURL: URL) throws -> String {
//        assert(!Thread.isMainThread)
        guard let file: UnsafeMutablePointer<FILE> = fopen(fileURL.path, "r") else { throw FileLineReaderError.cannotOpenFile }
        
        var lineRead: UnsafeMutablePointer<CChar>?
        var bufsize: Int = 0
        var lineString = ""
        fseek(file, -200, SEEK_END)
        while getline(&lineRead, &bufsize, file) != eofMarker {
            lineString = String(cString: lineRead!).trimmingCharacters(in: .newlines)
        }
        free(lineRead)
        fseek(file, 0, SEEK_SET)
        fclose(file)
        return lineString
    }
}

