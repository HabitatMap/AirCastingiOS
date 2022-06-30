// Created by Lunar on 29/06/2022.
//

import SwiftUI

struct XMarkButton: View {
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.aircastingDarkGray)
                            .imageScale(.large)
                            .font(.body)
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

struct XmarkButton_Previews: PreviewProvider {
    static var previews: some View {
        XMarkButton()
    }
}
