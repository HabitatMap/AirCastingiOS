// Created by Lunar on 04/08/2021.
//

import Foundation
import Resolver

protocol BluetoothPermisionsChecker {
    func isBluetoothDenied() -> Bool
}

extension NewBluetoothManager: BluetoothPermisionsChecker {}
