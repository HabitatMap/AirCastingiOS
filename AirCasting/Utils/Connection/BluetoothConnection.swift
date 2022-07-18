import SwiftUI
import CoreData
import Resolver

final class BluetoothConnectionProtector: Connectable {
    
    enum BluetoothConnectionProtectorError: Error {
        case alreadyConnected
        case readError(Error)
    }
    
    @Injected private var persistenceController: PersistenceController
    
    func isAirBeamAvailableForNewConnection() -> Result<Void, Error> {
        var result: Result<Void, Error>!
        let context = persistenceController.editContext
        context.performAndWait {
            let request: NSFetchRequest<SessionEntity> = SessionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == %@ AND deviceType == $@", true, DeviceType.AIRBEAM3.rawValue)
            do {
                result = try context.fetch(request).count > 0 ? .failure(BluetoothConnectionProtectorError.alreadyConnected) : .success(())
            } catch {
                result = .failure(BluetoothConnectionProtectorError.readError(error))
            }
        }
            
        return result
    }
}
