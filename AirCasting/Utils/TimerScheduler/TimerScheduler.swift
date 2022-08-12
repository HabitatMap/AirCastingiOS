// Created by Lunar on 15/05/2022.
//

import Foundation

protocol TimerScheduler {
    func schedule(every: TimeInterval, closure: @escaping () -> Void) -> AnyObject
    func stop(token: AnyObject)
}
