// Created by Lunar on 01/12/2021.
//

import AirCastingStyling
import SwiftUI

struct SDSyncCompleteView: View {
    @Binding var creatingSessionFlowContinues: Bool
    @EnvironmentObject private var tabSelection: TabBarSelection
    var isSDClearProcess: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            ProgressView(value: 0.9)
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
            Spacer()
        }
        .padding()
    }
}

private extension SDSyncCompleteView {
    
    var compleateImage: some View {
        Image("4-connected")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
    
    var titleLabel: some View {
        Text(isSDClearProcess ? "SD card cleared" : Strings.SDSyncCompleteView.title)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(isSDClearProcess ? "SD inside your AirBeam was cleared sucesfully" : Strings.SDSyncCompleteView.message)
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
    }
    
    var continueButton: some View {
        Button {
            creatingSessionFlowContinues = false
            tabSelection.selection = TabBarSelection.Tab.dashboard
        } label: {
            Text(Strings.ABConnectedView.continueButton)
        }.buttonStyle(BlueButtonStyle())
    }
}

