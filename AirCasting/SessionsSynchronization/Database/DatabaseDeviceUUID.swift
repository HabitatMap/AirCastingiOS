// Created by Lunar on 04/08/2022.
//

import Foundation

extension Database {
    public struct DeviceUUID: Hashable {
        public let peripheralUUID: String
        
        public init(
            peripheralUUID: String
        ) {
            self.peripheralUUID = peripheralUUID
        }
    }
}
