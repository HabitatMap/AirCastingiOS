import SwiftUI
import CoreData
import Resolver

final class BluetoothConnectionProtector: ConnectionProtectable {
    
    enum BluetoothConnectionProtectorError: Error {
        case alreadyConnected
        case readError(Error)
    }
    
    @Injected private var database: SessionsFetchable
    
    func isAirBeamAvailableForNewConnection(peripheraUUID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let defaultPredicate =  NSPredicate(format: "deviceType == %@ AND type == %@",
                                            "1", SessionType.mobile.rawValue)
        let p1 = NSPredicate(format: "status == %li || status == %li",
                             SessionStatus.RECORDING.rawValue, SessionStatus.NEW.rawValue)
        let p2 = NSPredicate(format: "status == %li AND peripheralUUID == %@",
                             SessionStatus.DISCONNECTED.rawValue, peripheraUUID)
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [p1, p2])
        let predicateWithDefault = NSCompoundPredicate(andPredicateWithSubpredicates: [defaultPredicate, predicate])
        database.fetchSessions(constrained: .predicate(predicateWithDefault)) { predicated in
            switch predicated {
            case .success(let sessions):
                sessions.count > 0 ? completion(.failure(BluetoothConnectionProtectorError.alreadyConnected)) : completion(.success(()))
            case .failure(let error):
                completion(.failure(BluetoothConnectionProtectorError.readError(error)))
            }
        }
    }
}
