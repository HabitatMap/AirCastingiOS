import SwiftUI

public struct BorderedButtonStyle: ButtonStyle {
    
    var isSelected: Bool
    var thresholdColor: Color
    
    public init(isSelected: Bool, thresholdColor: Color) {
        self.isSelected = isSelected
        self.thresholdColor = thresholdColor
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .font(Font.moderate(size: 16))
            .foregroundColor(.aircastingDarkGray)
            .padding(.vertical, 4)
            .padding(.horizontal, 9)
            .background(isSelected ? (RoundedRectangle(cornerRadius: 8).strokeBorder(thresholdColor)) : (RoundedRectangle(cornerRadius: 10).strokeBorder(.clear)))
        
    }
}
