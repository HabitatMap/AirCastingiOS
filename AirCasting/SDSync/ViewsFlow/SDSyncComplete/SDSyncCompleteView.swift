// Created by Lunar on 01/12/2021.
//

import AirCastingStyling
import SwiftUI

struct SDSyncCompleteView<VM: SDSyncCompleteViewModel>: View {
    @StateObject var viewModel: VM
    @Binding var creatingSessionFlowContinues: Bool
    @EnvironmentObject private var tabSelection: TabBarSelector
    var isSDClearProcess: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            ProgressView(value: 0.994)
            Spacer()
            HStack() {
                Spacer()
                compleateImage
                Spacer()
            }
            Spacer()
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            continueButton
        }
        .padding()
        .background(Color.aircastingBackground.ignoresSafeArea())
    }
}

private extension SDSyncCompleteView {
    
    var compleateImage: some View {
        Image("4-connected")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    
    var titleLabel: some View {
        Text(isSDClearProcess ? Strings.SDSyncCompleteView.SDClearTitle : Strings.SDSyncCompleteView.title)
            .font(Fonts.moderateBoldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(isSDClearProcess ? Strings.SDSyncCompleteView.SDClearMessage : Strings.SDSyncCompleteView.message)
            .font(Fonts.moderateRegularHeading1)
            .foregroundColor(.aircastingGray)
    }
    
    var continueButton: some View {
        Button {
            creatingSessionFlowContinues = false
            tabSelection.update(to: .dashboard)
        } label: {
            Text(Strings.Commons.continue)
        }
        .buttonStyle(BlueButtonStyle())
        .padding(.bottom, 15)
    }
}

