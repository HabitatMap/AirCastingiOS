// Created by Lunar on 12/01/2022.
//

import Foundation

class ShareLocationlessSessionViewModel: ObservableObject {
    @Published var alert: AlertInfo?
    @Published var showShareSheet: Bool = false
    @Published var file: URL?
    let session: SessionEntity
    let exitRoute: () -> Void
    let fileGenerator: CSVFileGenerator
    
    init(session: SessionEntity, fileGenerator: CSVFileGenerator, exitRoute: @escaping () -> Void) {
        self.session = session
        self.exitRoute = exitRoute
        self.fileGenerator = fileGenerator
    }
    
    func shareFileTapped() {
        let result = fileGenerator.generateFile(for: session)
        
        switch result {
        case .success(let fileURL):
            Log.info("\(try! String(contentsOfFile: fileURL.path))")
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                Log.error("Failed to delete session file")
            }
            exitRoute()
        case .failure(_):
            getAlert()
        }
    }
    
    func cancelTapped() {
        exitRoute()
    }
    
    func sharingFinished() {
        showShareSheet = false // this is kind of redundant, but also necessary for the shareSessionModal to disappear
        exitRoute()
    }
    
    private func getAlert() {
        DispatchQueue.main.async {
            self.alert = InAppAlerts.failedSharingAlert()
        }
    }
}
