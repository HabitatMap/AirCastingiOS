// Created by Lunar on 12/01/2022.
//

import Foundation

class ShareLocationlessSessionViewModel: ObservableObject {
    @Published var alert: AlertInfo?
    @Published var showShareSheet: Bool = false
    @Published var file: URL?
    @Published var loaderVisible: Bool = false
    private let session: SessionEntity
    private let exitRoute: () -> Void
    private let fileGenerationController: GenerateSessionFileController
    
    init(session: SessionEntity, fileGenerationController: GenerateSessionFileController, exitRoute: @escaping () -> Void) {
        self.session = session
        self.exitRoute = exitRoute
        self.fileGenerationController = fileGenerationController
    }
    
    func shareFileTapped() {
        loaderVisible = true
        DispatchQueue.global(qos: .background).async { [self] in // prepare file in background
            let result = fileGenerationController.generateFile(for: self.session)
            
            DispatchQueue.main.async { [self] in
                self.loaderVisible = false
                switch result {
                case .success(let fileURL):
                    file = fileURL
                    showShareSheet = true
                case .failure(_):
                    getAlert()
                }
            }
        }
    }
    
    func cancelTapped() {
        exitRoute()
    }
    
    func sharingFinished() {
        DispatchQueue.global(qos: .background).async {
            if let file = self.file {
                do {
                    try FileManager.default.removeItem(at: file)
                } catch {
                    Log.error("Failed to delete session file: \(error)")
                }
            }
        }
        showShareSheet = false // this is redunant but necessary for the exit route to work
        exitRoute()
    }
    
    func getSharePage() -> ActivityViewController? {
        guard file != nil else { return nil }
        return ActivityViewController(sharingFile: true, itemToShare: file!) { activityType, completed, returnedItems, error in
            self.sharingFinished()
        }
    }
    
    private func getAlert() {
        DispatchQueue.main.async {
            self.alert = InAppAlerts.failedSharingAlert()
        }
    }
}
