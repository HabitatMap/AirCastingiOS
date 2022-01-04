// Created by Lunar on 04/01/2022.
//

import SwiftUI

struct ToastMessage: View {
    @State var isShowing: Bool = true
    var message: String
    var duration = 3.0
    
    var body: some View {
            VStack {
                if isShowing {
                    Spacer()
                    HStack {
                        Text(message)
                            .font(.footnote)
                            .padding(.leading)
                            .padding(.trailing)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.black
                                    .opacity(0.5))
                    .cornerRadius(20)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
}

struct ToastMessage_Previews: PreviewProvider {
    static var previews: some View {
        ToastMessage(message: "Hello there")
    }
}
