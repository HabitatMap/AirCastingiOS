// Created by Lunar on 19/11/2021.
//

import Foundation

class SDCardCSVFileFactory {
    enum Header: Int {
        case index      = 0
        case uuid       = 1
        case date       = 2
        case time       = 3
        case latitude   = 4
        case longitude  = 5
        case f          = 6
        case c          = 7
        case k          = 8
        case rh         = 9
        case pm1        = 10
        case pm2_5      = 11
        case pm10       = 12
    }
}
