// Created by Lunar on 21/10/2022.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct ReconnectSessionCardView: View {
    @StateObject var viewModel: ReconnectSessionCardViewModel
    @EnvironmentObject var selectedSection: SelectedSection
    
    var body: some View {
        Spacer()
        VStack(alignment: .leading, spacing: 5) {
            header
            content
        }
        .foregroundColor(.aircastingGray)
        .padding()
        .background(
            Color.aircastingBackground
                .cardShadow()
        )
        .overlay(Rectangle().frame(width: nil, height: 4, alignment: .top).foregroundColor(Color.red), alignment: .top)
    }
    
    var header: some View {
        SessionHeaderView(
            action: {},
            isExpandButtonNeeded: false,
            isMenuNeeded: false,
            isCollapsed: .constant(false),
            session: viewModel.session)
    }
    
    var content: some View {
        VStack(spacing: 15) {
            Text(Strings.ReconnectSessionCardView.heading)
                .font(Fonts.moderateBoldHeading1)
                .foregroundColor(.darkBlue)
                .multilineTextAlignment(.center)
            Text(Strings.ReconnectSessionCardView.description)
                .font(Fonts.moderateRegularHeading3)
                .multilineTextAlignment(.center)
            reconnectionLabel
            finishAndDontSyncButton
                .padding()
        }
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
        .padding()
    }
    
    var reconnectionLabel: some View {
        Button {
            if !viewModel.isSpinnerOn {
                // Custom method of button disable: this can keep the UI style always the same
                // ... but do nothing when needed (as the button would be correctly disabled)
                viewModel.onRecconectTap()
            }
        } label: {
            ZStack(alignment: .center) {
                HStack(alignment: .center) {
                    Text(Strings.ReconnectSessionCardView.reconnectLabel)
                }
                if viewModel.isSpinnerOn {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing)
                    }
                }
            }
        }
        .font(Fonts.muliBoldHeading1)
        .buttonStyle(BlueButtonStyle())
    }
    
    var finishAndDontSyncButton: some View {
        Button(Strings.ReconnectSessionCardView.finishSessionLabel) {
            viewModel.onFinishDontSyncTapped {
                selectedSection.mobileSessionWasFinished = true
            }
        }
        .foregroundColor(.accentColor)
        .font(Fonts.moderateRegularHeading2)
    }
}
