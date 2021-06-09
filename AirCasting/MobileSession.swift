// Created by Lunar on 07/06/2021.
//

import Foundation
import CoreBluetooth

class MobileSession {
    var peripheral: CBPeripheral
    var session: Session
    
    init(peripheral: CBPeripheral, session: Session) {
        self.peripheral = peripheral
        self.session = session
    }
}
