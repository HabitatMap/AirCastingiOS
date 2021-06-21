// Created by Lunar on 17/06/2021.
//

import SwiftUI

struct MyAccountView: View {
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                
                Text("You aren’t currently logged in")
                    .foregroundColor(.aircastingGray)
                    .padding()
                
                Button(action: {
                }) {
                    Group {
                        HStack {
                            Text("Create an account")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding(.horizontal)
                    }
                } .buttonStyle(BlueButtonStyle())
                .padding()
                
                Button(action: {
                }) {
                    Group {
                        HStack {
                            Text("Login in")
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
                Spacer()
            }
        }
        .navigationTitle("My account")
    }
}

#if DEBUG
struct MyAccountView_Previews: PreviewProvider {
    static var previews: some View {
        MyAccountView()
    }
}
#endif
