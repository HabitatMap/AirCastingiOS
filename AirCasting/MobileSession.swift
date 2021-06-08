// Created by Lunar on 07/06/2021.
//

import Foundation
import CoreBluetooth

class MobileSession {
    var peripheral: CBPeripheral
    var session: SessionEntity
    
    init(peripheral: CBPeripheral, session: SessionEntity) {
        self.peripheral = peripheral
        self.session = session
    }
}
