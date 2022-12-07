// Created by Lunar on 16/11/2022.
//

import Foundation

protocol BluetoothConnectionObserver: AnyObject {
    func didDisconnect(device: any BluetoothDevice)
}
