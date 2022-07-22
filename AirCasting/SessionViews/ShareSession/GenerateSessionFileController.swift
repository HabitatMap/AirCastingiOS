// Created by Lunar on 12/01/2022.
//

import Foundation

protocol GenerateSessionFileController {
    func generateFile(for session: SessionEntity) -> Result<URL, Error>
}

struct DefaultGenerateSessionFileController: GenerateSessionFileController {
    private let fileGenerator: CSVFileGenerator
    private let fileZppier: FileZipper
    
    init(fileGenerator: CSVFileGenerator, fileZipper: FileZipper) {
        self.fileGenerator = fileGenerator
        self.fileZppier = fileZipper
    }
    
    func generateFile(for session: SessionEntity) -> Result<URL, Error> {
        let fileContent = prepareFileContent(for: session)
        let fileName = session.name?.replacingOccurrences(of: " ", with: "_") ?? "session"
        let fileGenerationResult = fileGenerator.generateFile(content: fileContent, fileName: fileName)
        
        switch fileGenerationResult {
        case .success(let url):
            let zipResult = fileZppier.createZipFile(url, fileName: fileName, removeOriginalFile: true)
            return zipResult
        case .failure(_):
            return fileGenerationResult
        }
    }
    
    private func prepareFileContent(for session: SessionEntity) -> String {
        var content = ""
        let headers1 = "sensor_model, sensor_package, sensor_capability, sensor_units\n"
        let headers2 = "Timestamp, Value\n"
        session.allStreams.forEach({ stream in
            content.append(headers1)
            content.append("\(stream.sensorName ?? ""), \(stream.sensorPackageName ?? ""), \(stream.measurementType ?? ""), \(stream.unitName ?? "")\n")
            content.append(headers2)
            stream.allMeasurements?.forEach({ measurement in
                if let time = measurement.time {
                    content.append("\(time), \(measurement.value)\n")
                }
            })
        })
        return content
    }
}

struct DummyGenerateSessionFileController: GenerateSessionFileController {
    func generateFile(for session: SessionEntity) -> Result<URL, Error> { .success(URL(fileURLWithPath: "")) }
}
