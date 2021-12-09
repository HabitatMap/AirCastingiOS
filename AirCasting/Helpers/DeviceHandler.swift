// Created by Lunar on 29/11/2021.
//

import Foundation
import SwiftUI
import DeviceKit

struct DeviceHandler {
    // Listed every device that support the app but has BT lover then 5.0
    static let BTBelow5Devices: [Device] = [.iPhone4,
                                            .iPhone5,
                                            .iPhone5c,
                                            .iPhone5s,
                                            .iPhone6,
                                            .iPhone6Plus,
                                            .iPhone6s,
                                            .iPhone6sPlus,
                                            .iPhone7,
                                            .iPhone7Plus,
                                            .iPodTouch5,
                                            .iPodTouch6,
                                            .iPodTouch7,
                                            .iPad2,
                                            .iPad3,
                                            .iPad4,
                                            .iPad5,
                                            .iPad6,
                                            .iPad7,
                                            .iPad8,
                                            .iPad9,
                                            .iPadAir,
                                            .iPadAir2,
                                            .iPadMini2,
                                            .iPadMini3,
                                            .iPadMini4,
                                            .iPadPro9Inch,
                                            .iPadPro10Inch,
                                            .iPadPro12Inch,
                                            .iPadPro12Inch2]
    
    static func getDeviceNumber() -> Int {
        guard Device.current.isPhone else { return 0 }
        var arrayNumber = [String.Element]()
        let currentDeveice = Device.current
        currentDeveice.description.forEach { char in
            char.isNumber ? arrayNumber.append(char) : nil
        }
        let iPhoneNumber = Int(String(arrayNumber)) ?? 0
        return iPhoneNumber
    }
}
