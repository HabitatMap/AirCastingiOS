// Created by Lunar on 26/07/2021.
//

import Foundation
import Combine

// This is not super ideal, but should do for now. We need to think about how to handle such global alerts in the future.
class OfflineMessageViewModel: SessionSynchronizerErrorStream, ObservableObject {
    @Published var showOfflineMessage: Bool = false
    
    func handleSyncError(_ error: SessionSynchronizerError) {
        guard error == .noConnection else { return }
        DispatchQueue.main.async {
            self.showOfflineMessage = true
        }
    }
}
