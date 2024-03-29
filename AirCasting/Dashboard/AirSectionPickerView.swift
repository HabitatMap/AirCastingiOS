// Created by Lunar on 06/05/2021.
//

import SwiftUI

struct AirSectionPickerView: View {
    @Binding var selection: DashboardSection
    
    var body: some View {
        ScrollViewReader { scrollReader in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(DashboardSection.allCases, id: \.self) { section in
                        Button(section.localizedString) {
                            if section == .mobileDormant || section == .fixed {
                                scrollReader.scrollTo(DashboardSection.fixed)
                            } else if section == .mobileActive {
                                scrollReader.scrollTo(DashboardSection.following)
                            }
                            selection = section
                        }.onChange(of: selection, perform: { section in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                section == .following ? scrollReader.scrollTo(DashboardSection.following) : nil
                                section == .fixed ? scrollReader.scrollTo(DashboardSection.fixed) : nil
                            }
                        })
                        .buttonStyle(PickerButtonStyle(isSelected: section == selection))
                        .id(section)
                    }
                }
            }
            .onTapGesture { } // Fix for a bug that caused buttons to not be fully tappable. SwiftUI 🤷‍♂️
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

struct PickerButtonStyle: ButtonStyle {
    var isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(isSelected ? Color.accentColor : Color.aircastingGray)
            .font(Fonts.muliRegularHeading3)
            .frame(maxHeight: 30)
            .background(Color.aircastingBackground)
            .padding(.trailing, 10)
            .padding(.top)
            .padding(.bottom, 5)
    }
}
