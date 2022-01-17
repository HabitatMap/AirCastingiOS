// Created by Lunar on 12/01/2022.
//

import Foundation

protocol CSVFileGenerator {
    func generateFile(content: String, fileName: String) -> Result<URL, Error>
}

struct DefaultCSVFileGenerator: CSVFileGenerator {
    func generateFile(content: String, fileName: String) -> Result<URL, Error> {
        let fileManager = FileManager.default
        do {
            let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let directoryURL = path.appendingPathComponent(fileName)
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: false, attributes: nil)
            let fileURL = directoryURL.appendingPathComponent("\(fileName).csv")
            // This is in case removing file previously failed
            try? FileManager.default.removeItem(at: fileURL)
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return .success(directoryURL)
        } catch {
            Log.error("error creating file: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}

struct DummyCSVFileGenerator: CSVFileGenerator {
    func generateFile(content: String, fileName: String) -> Result<URL, Error> { return .success(URL(fileURLWithPath: "")) }
}
