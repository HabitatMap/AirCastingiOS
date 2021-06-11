// Created by Lunar on 08/06/2021.
//

import SwiftUI

struct AirBorderedButtonStyle: ButtonStyle {
    
    var isSelected: Bool
    var thresholdColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .font(Font.moderate(size: 16))
            .foregroundColor(.aircastingDarkGray)
            .padding(.vertical, 4)
            .padding(.horizontal, 9)
            .background(isSelected ? (RoundedRectangle(cornerRadius: 8).strokeBorder(thresholdColor)) : (RoundedRectangle(cornerRadius: 10).strokeBorder(.clear)))
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
