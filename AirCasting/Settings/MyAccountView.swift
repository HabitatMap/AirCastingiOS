// Created by Lunar on 17/06/2021.
//

import AirCastingStyling
import SwiftUI

struct MyAccountView: View {
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                loggedOutInformationLabel
                createAccountButton
                logInButton
                Spacer()
            }
        }
        .navigationTitle(Strings.Commons.myAccount)
    }
}


private var loggedOutInformationLabel: some View {
    Text(Strings.MyAccountSettings.notLogged)
        .foregroundColor(.aircastingGray)
        .padding()
}

private var createAccountButton: some View {
    Button(action: {}) {
        Group {
            HStack {
                Text(Strings.MyAccountSettings.createAccount)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(.horizontal)
        }
    }
    .buttonStyle(BlueButtonStyle())
    .padding()
}

private var logInButton: some View {
    Button(action: {}) {
        Group {
            HStack {
                Text(Strings.MyAccountSettings.logIn)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(lineWidth: 1.0)
        )
    }
    .padding()
}

#if DEBUG
struct MyAccountView_Previews: PreviewProvider {
    static var previews: some View {
        MyAccountView()
    }
}
#endif
