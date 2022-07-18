// Created by Lunar on 12/04/2022.
//

import Foundation
import SwiftUI

struct ProtectedScreen: View {
    
    var body: some View {
        VStack(alignment: .center) {
            Image(systemName: "exclamationmark.shield.fill")
                .resizable()
                .scaledToFit()
            Text(Strings.ProtectedScreen.title)
                .font(Fonts.moderateBoldTitle1)
                .foregroundColor(.accentColor)
        }.padding()
    }
}
