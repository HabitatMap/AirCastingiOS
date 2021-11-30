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
}
