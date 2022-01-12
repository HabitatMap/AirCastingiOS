// Created by Lunar on 12/01/2022.
//

import Foundation

protocol CSVFileGenerator {
    func generateFile(for session: SessionEntity) -> Result<URL, Error>
}

struct DefaultCSVFileGenerator: CSVFileGenerator {
    func generateFile(for session: SessionEntity) -> Result<URL, Error> {
        
        var csvString = ""
        
        
        let fileManager = FileManager.default
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent("CSVSession.csv")
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            return .success(fileURL)
        } catch {
            print("error creating file: \(error)")
            return .failure(error)
        }
    }
}

struct DummyCSVFileGenerator: CSVFileGenerator {
    func generateFile(for session: SessionEntity) -> Result<URL, Error> { return .success(URL(fileURLWithPath: "")) }
}
