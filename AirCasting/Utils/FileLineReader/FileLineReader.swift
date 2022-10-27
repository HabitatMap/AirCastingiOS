// Created by Lunar on 26/11/2021.
//

import Foundation

enum FileLineReaderProgress: Equatable {
    case endOfFile
    case line(String)
}

enum FileLineReaderError: Error {
    case cannotOpenFile
}

protocol FileLineReader {
    /// Will read each line and pass it to progress. When end of file is hit it will pass in .endOfFile. Note that this method is synchronous.
    func readLines(of: URL, progress: (FileLineReaderProgress) -> Void) throws
    /// Will return last line of file
    func readLastNonEmptyLine(of fileURL: URL) throws -> String?
}
