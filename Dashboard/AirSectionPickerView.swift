// Created by Lunar on 06/05/2021.
//

import SwiftUI

struct AirSectionPickerView: View {
    
    @Binding var selection: SelectedSection
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(SelectedSection.allCases, id: \.self) { section in
                    Button(section.rawValue) {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            selection = section
                        }
                    }
                    .buttonStyle(PickerButtonStyle(isSelected: section == selection))
                }
            }
        }
    }
}

struct AirSectionPickerView_Previews: PreviewProvider {
    static var previews: some View {
        AirSectionPickerView(selection: .constant(.mobileActive))
            .padding()
            .frame(width: 300)
            .previewLayout(.sizeThatFits)
    }
}

enum SelectedSection: String, CaseIterable {
    case following = "Following"
    case mobileActive = "Mobile active"
    case mobileDormant = "Mobile dormant"
    case fixed = "Fixed"
}

struct PickerButtonStyle: ButtonStyle {
    var isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(isSelected ? Color.accentColor : Color.aircastingGray)
            .font(isSelected ? Font.muli(size: 16, weight: .bold) : Font.muli(size: 16, weight: .regular))
            .frame(maxHeight: 30)
            .background(Color.white)
            .padding(.horizontal)
            .padding(.top)
    }
}
