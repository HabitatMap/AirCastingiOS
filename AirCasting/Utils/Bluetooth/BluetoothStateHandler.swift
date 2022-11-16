// Created by Lunar on 16/11/2022.
//

import Foundation

protocol BluetoothStateHandler {
    var authorizationState: BluetoothDeviceAuthorizationState { get }
    var deviceState: BluetoothDeviceState { get }
    func forceBluetoothPermissionPopup()
}

extension NewBluetoothManager: BluetoothStateHandler {}
