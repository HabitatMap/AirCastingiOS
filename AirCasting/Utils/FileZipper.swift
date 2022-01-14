// Created by Lunar on 14/01/2022.
//

import Foundation
protocol FileZipper {
    func createZipFile(_ url: URL, fileName: String, removeOriginalFile: Bool) -> Result<URL, Error>
}
import ZipArchive

class SSZipFileZipper: FileZipper {
    func createZipFile(_ url: URL, fileName: String, removeOriginalFile: Bool) -> Result<URL, Error> {
        var newUrl = url
        let fileManager = FileManager.default
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let zipPath = path.appendingPathComponent(fileName + ".zip").path
        SSZipArchive.createZipFile(atPath: zipPath, withContentsOfDirectory: url.path, keepParentDirectory: false)
        if removeOriginalFile {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                Log.error("Failed to delete file: \(error)")
            }
        }
        newUrl = URL(fileURLWithPath: zipPath)
        return .success(newUrl)
    }
}
