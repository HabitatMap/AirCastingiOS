// Created by Lunar on 16/08/2022.
//

import SwiftUI
import AirCastingStyling

struct MicrophoneAutoCalibrationView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = MicrophoneAutoCalibrationViewModel()
    let onFinish: () -> Void
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            title
            switch viewModel.state {
            case .idle: idleStateView
            case .calibrating: inProgressView
            case .done: calibrationFinishedview
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
        .background(Color.aircastingBackground.ignoresSafeArea())
    }
    
    private var title: some View {
        Text("Microphone calibration")
            .foregroundColor(.aircastingDarkGray)
            .font(Fonts.muliSemiboldTitle1)
            .padding(.bottom, 30)
    }
    
    private var idleStateView: some View {
        Group {
            Image(systemName: "speaker.slash")
                .font(.system(size: 100).italic())
            Group {
                Text("Please put your phone in a quiet space and press \"Start\", the calibration will take aprox. 5sec")
                    .font(Fonts.muliMediumHeading2)
                Button("Start", action: { self.viewModel.calibrateTapped() })
                    .buttonStyle(BlueButtonStyle())
                    .padding(.top, 20)
            }.padding()
        }
    }
    
    private var inProgressView: some View {
        Group {
            ActivityIndicator(isAnimating: .constant(true), style: .large)
            Text("Microphone is calibrating. Please try to keep silence")
                .font(Fonts.muliMediumHeading2)
                .padding(.top, 20)
        }.padding()
    }
    
    private var calibrationFinishedview: some View {
        Group {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 100).italic())
            Group {
                Text("Microphone is calibrated")
                    .font(Fonts.muliMediumHeading2)
                    .padding(.top, 20)
                Button("Ok", action: { self.presentationMode.wrappedValue.dismiss() })
                    .buttonStyle(BlueButtonStyle())
                    .padding(.top, 20)
            }
        }.padding()
    }
}
