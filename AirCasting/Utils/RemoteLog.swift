// Created by Lunar on 04/12/2021.
//

import Foundation
import FirebaseCrashlytics

func remoteLog(_ msg: String) {
    #if !DEBUG
    Crashlytics.crashlytics().log(msg)
    #endif
}
