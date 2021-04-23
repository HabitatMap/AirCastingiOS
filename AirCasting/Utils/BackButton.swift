// Created by Lunar on 23/04/2021.
//

import SwiftUI

struct BackButton: View {
    let presentationMode: Binding<PresentationMode>
    
    var body: some View {
        Button(action: {
          self.presentationMode.wrappedValue.dismiss()
        }) {
          HStack {
            Image(systemName: "chevron.left")
                .renderingMode(.original)
          }
        }
    }
}
