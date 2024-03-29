// Created by Lunar on 06/02/2022.
//

import Foundation
import Resolver

protocol LogfileProvider {
    func logFileURLForSharing() -> URL?
}

class ShareLogsViewModel: ObservableObject {
    @Published var shareSheetPresented: Bool = false
    var file: URL? { logFileProvider.logFileURLForSharing() }
    private var logFileProvider: LogfileProvider { LoggerBuilder.shared.store }
    
    func shareLogsButtonTapped() {
        shareSheetPresented = true
    }
    
    func sharingFinished() {
        shareSheetPresented = false
    }
}
