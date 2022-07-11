// Created by Lunar on 18/06/2021.
//

import SwiftUI
import AirCastingStyling
import Resolver

struct SettingsMyAccountView<VM: SettingsMyAccountViewModel>: View {
    @ObservedObject var viewModel: VM
    @InjectedObject private var featureFlagsViewModel: FeatureFlagsViewModel

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                logInLabel
                signOutButton
                if featureFlagsViewModel.enabledFeatures.contains(.deleteAccount) {
                    deleteProfileButton
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Spacer()
            }
        }
        .navigationTitle(Strings.Commons.myAccount)
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
    }
}

private extension SettingsMyAccountView {
    var logInLabel: some View {
        Text(Strings.SignOutSettings.logged + "\(KeychainStorage(service: Bundle.main.bundleIdentifier!).getProfileData(for: .email))")
            .foregroundColor(.aircastingGray)
            .font(Fonts.muliRegularHeading3)
            .padding()
    }
    
    var signOutButton: some View {
        Button(action: {
            viewModel.signOutButtonTapped()
        }) {
            Group {
                HStack {
                    Text(Strings.SignOutSettings.signOut)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding(.horizontal)
            }
        }
        .font(Fonts.muliBoldHeading1)
        .buttonStyle(BlueButtonStyle())
        .padding()
    }
    
    var deleteProfileButton: some View {
        Button {
            viewModel.deleteButtonTapped()
        } label: {
            Text(Strings.SignOutSettings.deleteAccount)
        }
        .foregroundColor(.red)
        .padding(.bottom, 20)
        .padding()
    }
}
