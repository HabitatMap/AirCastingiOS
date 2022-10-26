// Created by Lunar on 26/10/2022.
//

import Foundation

struct CharacteristicUUID: Hashable {
    let value: String
}

protocol BluetoothCommunicator {
    typealias CharacteristicObserverAction = (Result<Data?, Error>) -> Void
    
    /// Adds an entry to observers of a particular characteristic
    /// - Parameters:
    ///   - characteristic: UUID of characteristic to observe
    ///   - timeout: a timeout after which the error is produced
    ///   - notify: block called each time characteristic changes (either changes value or throws an error)
    /// - Returns: Opaque token to use when un-registering
    func subscribeToCharacteristic(_ characteristic: CharacteristicUUID, timeout: TimeInterval?, notify: @escaping CharacteristicObserverAction) -> AnyHashable
    
    /// Removes an entry from observing characteristic
    /// - Parameter token: Opaque token received on subscription
    /// - Returns: A `Bool` value indicating if a given token was successfuly removed. Only reason it can fail is double unregistration.
    @discardableResult func unsubscribeCharacteristicObserver(_ token: AnyHashable) -> Bool
}

extension BluetoothCommunicator {
    func subscribeToCharacteristic(_ characteristic: CharacteristicUUID, notify: @escaping CharacteristicObserverAction) -> AnyHashable {
        subscribeToCharacteristic(characteristic, timeout: nil, notify: notify)
    }
}
