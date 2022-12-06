// Created by Lunar on 05/12/2022.
//

import Foundation

protocol BluetoothDevice {
    var name: String? { get }
    var uuid: String { get }
}
