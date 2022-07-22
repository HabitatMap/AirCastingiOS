// Created by Lunar on 04/05/2022.
//

import Foundation

struct PartialExternalSession {
    let id: Int
    let uuid: SessionUUID
    let provider: String
    let name: String
    let startTime: Date
    let endTime: Date
    let longitude: Double
    let latitude: Double
    
    static var mock: PartialExternalSession {
        let session =  self.init(id: 1,
                                 uuid: "202411",
                                 provider: "OpenAir",
                                 name: "KAHULUI, MAUI",
                                 startTime: DateBuilder.getFakeUTCDate() - 60,
                                 endTime: DateBuilder.getFakeUTCDate(),
                                 longitude: 19.944544,
                                 latitude: 50.049683)
        return session
    }
}
