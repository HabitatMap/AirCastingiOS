// Created by Lunar on 12/01/2022.
//

import Foundation

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
        let result = fileGenerator.generateFile(content: fileContent, fileName: session.name ?? "session")
        
        switch result {
        case .success(let url):
            return .success(url)
        case .failure(_):
            return result
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
    
    private func zipFile(_ url: URL) -> Result<URL, Error> {
        let fm = FileManager.default
        var archiveUrl: URL?
        let coordinator = NSFileCoordinator()
        var error: NSError?
        coordinator.coordinate(readingItemAt: url, options: [.forUploading], error: &error) { (zipUrl) in
            let tmpUrl = try! fm.url(
                    for: .itemReplacementDirectory,
                    in: .userDomainMask,
                    appropriateFor: zipUrl,
                    create: true
                ).appendingPathComponent("archive.zip")
            Log.info("file url: \(url)")
            Log.info("temp url: \(tmpUrl)")
            Log.info("zip url: \(zipUrl)")
            try? fm.moveItem(at: zipUrl, to: tmpUrl)

            // store the URL so we can use it outside the block
            archiveUrl = tmpUrl
        }
        if let newUrl = archiveUrl {
            return .success(newUrl)
        } else {
            return .success(url)
        }
    }
}

struct DummyGenerateSessionFileController: GenerateSessionFileController {
    func generateFile(for session: SessionEntity) -> Result<URL, Error> { .success(URL(fileURLWithPath: "")) }
}
