// Created by Lunar on 08/06/2021.
//

import SwiftUI

struct AirBorderedButtonStyle: ButtonStyle {
    
    var isSelected: Bool
    var thresholdColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(.aircastingDarkGray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? (RoundedRectangle(cornerRadius: 10).strokeBorder(thresholdColor)) : (RoundedRectangle(cornerRadius: 10).strokeBorder(.clear)))
//            .padding(-3)
    }
}

#if DEBUG
struct AirBorderedButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Button("10") {}
            .buttonStyle(AirBorderedButtonStyle(isSelected: true,
                                                thresholdColor: Color.aircastingGreen))
            .padding()
    }
}
#endif
