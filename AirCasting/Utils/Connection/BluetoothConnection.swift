import SwiftUI
import CoreData

enum BluetoothConnectionError: Error {
    case BTConnectionError
}

class BluetoothConnectionProtector: Connectable {
    @StateObject var coreDataHook: CoreDataHook
    
    init(context: NSManagedObjectContext) {
        self._coreDataHook = .init(wrappedValue: CoreDataHook(context: context))
    }
    
    func isAvailableForNewConnection() -> Result<Void, Error> {
        guard let sessions = coreDataHook.sessions as? [SessionEntity] else { return .failure(BluetoothConnectionError.BTConnectionError) }
        if sessions.contains(where: { $0.isActive == true && $0.deviceType == .AIRBEAM3 }) {
            return .failure(BluetoothConnectionError.BTConnectionError)
        }
        return .success(())
    }
}
