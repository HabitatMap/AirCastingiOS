import Foundation
import Resolver

final class MicrophoneManager {
    @Injected private var microphone: Microphone
    
    private var controller: Any?

    func startRecording(session: Session) throws {
        let sessionStopper = Resolver.resolve(SessionStoppable.self, args: session)
        let controller = LevelMeasurementController(
            sampler: DecibelSampler(microphone: microphone),
            measurementSaver: DecibelMeasurementSaveable(session: session),
            sessionStopper: sessionStopper,
            timer: FoundationTimerScheduler()
        )
        controller.startMeasuring(with: 1.0)
        self.controller = controller
    }
    
    func stopRecording() {
        controller = nil
    }
}
