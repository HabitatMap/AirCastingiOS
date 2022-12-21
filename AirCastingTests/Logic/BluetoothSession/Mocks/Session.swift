// Created by Lunar on 06/12/2022.
//

import Foundation
@testable import AirCasting

extension Session {
    static let mobileAirBeamMock = Session(uuid: "123", type: .mobile, name: "Mobile Session", deviceType: .AIRBEAM3, location: .undefined, startTime: DateBuilder.getFakeUTCDate())
    
    static let mobileAirBeamLocationlessMock = Session(uuid: "123", type: .mobile, name: "Mobile Session", deviceType: .AIRBEAM3, location: .undefined, startTime: DateBuilder.getFakeUTCDate(), contribute: false, locationless: true)
}
