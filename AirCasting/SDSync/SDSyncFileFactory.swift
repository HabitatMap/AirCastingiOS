// Created by Lunar on 19/11/2021.
//

import Foundation


class SDCardCSVFileFactory {
    private let DIR_NAME = "sync"
    private let MOBILE_FILE_NAME = "mobile.csv"
    private let FIXED_FILE_NAME = "fixed.csv"

    enum Header {
        case index
        case uuid
        case date
        case time
        case lattitude
        case longitude
        case f
        case c
        case k
        case rh
        case pm1
        case pm2_5
        case pm10
    }

//    func getMobileFile() -> File {
//        return getFile(MOBILE_FILE_NAME)
//    }
//
//    func getFixedFile() -> File {
//        return getFile(FIXED_FILE_NAME)
//    }
//
//    func getFile(stepType: SDCardReader.StepType) -> File {
//        return when(stepType) {
//            SDCardReader.StepType.MOBILE -> getMobileFile()
//            SDCardReader.StepType.FIXED_WIFI -> getFixedFile()
//            SDCardReader.StepType.FIXED_CELLULAR -> getFixedFile()
//        }
//    }
//
//    private func getFile(fileName: String): File {
//        val dir = mContext.getExternalFilesDir(DIR_NAME)
//        return File(dir, fileName)
//    }
}
