// Created by Lunar on 16/08/2022.
//

import Resolver
import SwiftUI
import AirCastingStyling

class MicrophoneCalibrationViewModel: ObservableObject {
    enum CurrentState {
        case idle
        case calibrating
        case done
    }
    @Published var state: CurrentState = .idle
    @Published var alert: AlertInfo?
    
    @Injected private var calibrator: MicrophoneCalibration
    @Injected private var store: MicrophoneCalibrationValueWritable
    
    func calibrateTapped() {
        Log.info("Mic calibration started")
        guard calibrator.isAvailable else {
            Log.info("Microphone is busy, calibration aborted")
            alert = InAppAlerts.microphoneUnavailableForCalibration()
            return
        }
        state = .calibrating
        calibrator.startCalibration { [weak self] result in
            do {
                let newZero = try result.get().lowestPower
                Log.info("Mic calibration ended with new low power: \(newZero)")
                self?.store.zeroLevelAdjustment = newZero
                self?.state = .done
                Log.info("Mic calibration store adjusted.")
            } catch {
                Log.info("Mic calibration failed with error: \(error.localizedDescription)")
                self?.alert = InAppAlerts.microphoneCalibrationError(error: error)
                self?.state = .idle
            }
        }
    }
}

struct MicrophoneCalibrationView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = MicrophoneCalibrationViewModel()
    let onFinish: () -> Void
    
    var body: some View {
        VStack(alignment: .center) {
            switch viewModel.state {
            case .idle:
                Image(systemName: "speaker.slash")
                Text("Please go somewhere quiet, the microphone will calibrate within 5sec.")
                    .font(Fonts.muliMediumHeading2)
                Button("Start", action: { self.viewModel.calibrateTapped() })
                    .buttonStyle(BlueButtonStyle())
            case .calibrating:
                ActivityIndicator(isAnimating: .constant(true), style: .large)
                Text("Microphone is calibrating. Please try to keep silence")
                    .font(Fonts.muliMediumHeading2)
            case .done:
                Image(systemName: "checkmark.circle")
                Text("Microphone is calibrated")
                    .font(Fonts.muliMediumHeading2)
                Button("Ok", action: { self.presentationMode.wrappedValue.dismiss() })
                    .buttonStyle(BlueButtonStyle())
            }
        }
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
    }
}
