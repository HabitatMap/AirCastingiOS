// Created by Lunar on 12/01/2022.
//

import Foundation

class ShareLocationlessSessionViewModel: ObservableObject {
    @Published var alert: AlertInfo?
    @Published var showShareSheet: Bool = false
    @Published var file: URL?
    let session: SessionEntity
    let exitRoute: () -> Void
    let fileGenerationController: GenerateSessionFileController
    
    init(session: SessionEntity, fileGenerationController: GenerateSessionFileController, exitRoute: @escaping () -> Void) {
        self.session = session
        self.exitRoute = exitRoute
        self.fileGenerationController = fileGenerationController
    }
    
    func shareFileTapped() {
        let result = fileGenerationController.generateFile(for: session)
        
        switch result {
        case .success(let fileURL):
            file = fileURL
            showShareSheet = true
        case .failure(_):
            getAlert()
        }
    }
    
    func cancelTapped() {
        exitRoute()
    }
    
    func sharingFinished() {
        if let file = file {
            do {
                try FileManager.default.removeItem(at: file)
            } catch {
                Log.error("Failed to delete session file: \(error)")
            }
        }
        exitRoute()
    }
    
    private func getAlert() {
        DispatchQueue.main.async {
            self.alert = InAppAlerts.failedSharingAlert()
        }
    }
}
