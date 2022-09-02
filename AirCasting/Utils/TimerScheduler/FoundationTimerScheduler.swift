// Created by Lunar on 15/05/2022.
//

import Foundation

final class FoundationTimerScheduler: TimerScheduler {
    func schedule(every interval: TimeInterval, closure: @escaping () -> Void) -> AnyObject {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in closure() }
    }
    
    func stop(token: AnyObject) {
        guard let token = token as? Timer else { fatalError("Token received is not what was returned from schedule func!") }
        token.invalidate()
    }
}
