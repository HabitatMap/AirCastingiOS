// Created by Lunar on 18/06/2021.
//

import SwiftUI

struct MyAccountViewSingOut: View {
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                
                Text("You are currently logged in as jan.krzempek@lunarlogic.io")
                    .foregroundColor(.aircastingGray)
                    .padding()
                
                Button(action: {
                }) {
                    Group {
                        HStack {
                            Text("Sign Out")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding(.horizontal)
                    }
                } .buttonStyle(BlueButtonStyle())
                .padding()
                Spacer()
            }
        }
        .navigationTitle("My account")
    }
}

#if DEBUG
struct MyAccountViewSingOut_Previews: PreviewProvider {
    static var previews: some View {
        MyAccountViewSingOut()
    }
}
#endif
