// Created by Lunar on 25/07/2021.
//

import Foundation

protocol ScheduledTimerSettable {
    func setupRepeatingTimer(for: TimeInterval, block: @escaping () -> Void) -> Cancellable
}

class ScheduledTimerSettableMock: ScheduledTimerSettable {
    private var block: (() -> Void)?
    
    var latestTimer: TimeInterval?
    
    func setupRepeatingTimer(for timeInterval: TimeInterval, block: @escaping () -> Void) -> Cancellable {
        self.block = block
        self.latestTimer = timeInterval
        return EmptyCancellable()
    }
    
    func fireTimer() {
        block?()
    }
}

class ScheduledTimerSetter: ScheduledTimerSettable {
    private var undelyingTimer: Timer?
    
    func setupRepeatingTimer(for interval: TimeInterval, block: @escaping () -> Void) -> Cancellable {
        self.undelyingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { _ in
            block()
        })
        return TimerCancellable(timer: self.undelyingTimer!)
    }
    
    private class TimerCancellable: Cancellable {
        private weak var timer: Timer?
        
        init(timer: Timer) {
            self.timer = timer
        }
        
        func cancel() {
            timer?.invalidate()
        }
        
        deinit {
            timer?.invalidate()
        }
    }
}
