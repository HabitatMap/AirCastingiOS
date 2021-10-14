// Created by Lunar on 06/05/2021.
//

import SwiftUI

struct AirSectionPickerView: View {
    
    @Binding var selection: SelectedSection
    
    var body: some View {
        ScrollViewReader { scrollReader in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(SelectedSection.allCases, id: \.self) { section in
                        Button(section.localizedString) {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                if section == .mobileDormant {
                                    scrollReader.scrollTo(SelectedSection.fixed)
                                } else if section == .mobileActive {
                                    scrollReader.scrollTo(SelectedSection.following)
                                }
                                selection = section
                            }
                        }
                        .buttonStyle(PickerButtonStyle(isSelected: section == selection))
                        .id(section)
                    }
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
    
    var localizedString: String {
        NSLocalizedString(rawValue, comment: "")
    }
}

struct PickerButtonStyle: ButtonStyle {
    var isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(isSelected ? Color.accentColor : Color.aircastingGray)
            .font(isSelected ? Font.muli(size: 16, weight: .bold) : Font.muli(size: 16, weight: .regular))
            .frame(maxHeight: 20)
            .background(Color.white)
            .padding(.horizontal, 10)
            .padding(.top)
    }
}
