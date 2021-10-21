// Created by Lunar on 06/05/2021.
//

import SwiftUI
import Combine

struct AirSectionPickerView: View {
    
    @Binding var selection: SelectedSection
    
    var body: some View {
        ScrollViewReader { scrollReader in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(SelectedSection.allCases, id: \.self) { section in
                        Button(section.localizedString) {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                if section == .mobileDormant || section == .fixed {
                                    scrollReader.scrollTo(SelectedSection.fixed)
                                } else if section == .mobileActive {
                                    scrollReader.scrollTo(SelectedSection.following)
                                }
                                selection = section
                            }
                        }.onChange(of: selection, perform: {
                            $0 == .following ? scrollReader.scrollTo(SelectedSection.following) : nil
                        })
                        .buttonStyle(PickerButtonStyle(isSelected: section == selection))
                        .id(section)
                    }
                }
                .padding(.leading, 8)
            }
        }
        .background(
            ZStack(alignment: .bottom) {
                Color.green
                    .frame(height: 3)
                    .shadow(color: Color.aircastingDarkGray.opacity(0.4),
                            radius: 6)
                    .padding(.horizontal, -30)
                Color.white
            }
        )
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
            .frame(maxHeight: 30)
            .background(Color.white)
            .padding(.horizontal, 10)
            .padding(.top)
    }
}
