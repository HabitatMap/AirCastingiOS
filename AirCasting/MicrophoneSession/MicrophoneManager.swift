import Foundation
import AVFoundation

final class MicrophoneManager: NSObject, ObservableObject {
    var isRecording: Bool { controller != nil }
    private var controller: Any?

    func startRecording(session: Session) throws {
        let controller = LevelMeasurementController(
            sampler: DecibelSampler(microphone: try AVMicrophone()),
            measurementSaver: DecibelMeasurementSaveable(session: session, locationService: LocationProvider()),
            timer: FoundationTimerScheduler()
        )
        controller.startMeasuring(with: 1.0)
        self.controller = controller
    }
    
    func stopRecording() {
        controller = nil
    }
    
    func recordPermissionGranted() -> Bool {
        AVAudioSession.sharedInstance().recordPermission == .granted
    }
    
    func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission(response)
    }
}
