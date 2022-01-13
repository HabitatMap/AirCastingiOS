// Created by Lunar on 12/01/2022.
//

import Foundation
import SSZipArchive

protocol GenerateSessionFileController {
    func generateFile(for session: SessionEntity) -> Result<URL, Error>
}

struct DefaultGenerateSessionFileController: GenerateSessionFileController {
    let fileGenerator: CSVFileGenerator
    
    init() {
        fileGenerator = DefaultCSVFileGenerator()
    }
    
    func generateFile(for session: SessionEntity) -> Result<URL, Error> {
        let fileContent = prepareFileContent(for: session)
        let fileName = session.name?.replacingOccurrences(of: " ", with: "_") ?? "session"
        let fileGenerationResult = fileGenerator.generateFile(content: fileContent, fileName: fileName)
        
        switch fileGenerationResult {
        case .success(let url):
            let zipResult = zipFile(url, fileName: fileName)
            return zipResult
        case .failure(_):
            return fileGenerationResult
        }
    }
    
    private func prepareFileContent(for session: SessionEntity) -> String {
        var content = ""
        let headers1 = "sensor_model, sensor_package, sensor_capability, sensor_units\n"
        let headers2 = "Timestamp, Value\n"
        session.allStreams?.forEach({ stream in
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
    
    private func zipFile(_ url: URL, fileName: String) -> Result<URL, Error> {
        var newUrl = url
        let fileManager = FileManager.default
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let zipPath = path.appendingPathComponent(fileName + ".zip").path
            SSZipArchive.createZipFile(atPath: zipPath, withContentsOfDirectory: url.path, keepParentDirectory: false)
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                Log.error("Failed to delete session file: \(error)")
            }
            newUrl = URL(fileURLWithPath: zipPath)
        } catch {
            Log.error("Failed to create zipped file: \(error)")
        }
        return .success(newUrl)
    }
}

struct DummyGenerateSessionFileController: GenerateSessionFileController {
    func generateFile(for session: SessionEntity) -> Result<URL, Error> { .success(URL(fileURLWithPath: "")) }
}
