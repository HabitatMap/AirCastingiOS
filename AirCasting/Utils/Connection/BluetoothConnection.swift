import SwiftUI
import CoreData

final class BluetoothConnectionProtector: Connectable {
    
    enum BluetoothConnectionProtector: Error {
        case alreadyConnected
    }
    
    private var coreDataHook: CoreDataHook
    
    init(context: NSManagedObjectContext) {
        self.coreDataHook = CoreDataHook(context: context)
    }
    
    func isAirBeamAvailableForNewConnection() -> Result<Void, Error> {
        guard let sessions = coreDataHook.sessions as? [SessionEntity] else { return .failure(BluetoothConnectionProtector.alreadyConnected) }
        if sessions.contains(where: { $0.isActive == true && $0.deviceType == .AIRBEAM3 }) {
            return .failure(BluetoothConnectionProtector.alreadyConnected)
        }
        return .success(())
    }
}
