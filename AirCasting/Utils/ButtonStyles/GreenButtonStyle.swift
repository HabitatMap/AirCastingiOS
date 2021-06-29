// Created by Lunar on 09/06/2021.
//

import SwiftUI

struct GreenButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.aircastingMint)
            .cornerRadius(5)
            .padding(-3)
            .shadow(color: .shadowColor, radius: 9, x: 0, y: 1)
    }
}
#if DEBUG
struct GreenButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button("AitButtonStyle") {}
            .buttonStyle(GreenButtonStyle())
    }
}
#endif
