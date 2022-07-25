//
//  MoreInfoPopupView.swift
//  AirCasting
//
//  Created by Lunar on 18/03/2021.
//

import SwiftUI

struct MoreInfoPopupView: View {
    var body: some View {
        ZStack {
            XMarkButton()
            VStack(alignment: .leading, spacing: 25) {
                Text(Strings.MoreInfoPopupView.text_1)
                    .font(Fonts.moderateBoldTitle2)
                    .foregroundColor(.accentColor)
                StringCustomizer.customizeString(Strings.MoreInfoPopupView.text_2,
                                                 using: [Strings.MoreInfoPopupView.mobile],
                                                 color: .accentColor,
                                                 standardFont: Fonts.muliRegularHeading3)
                StringCustomizer.customizeString(Strings.MoreInfoPopupView.text_3,
                                                 using: [Strings.MoreInfoPopupView.fixed],
                                                 color: .accentColor,
                                                 standardFont: Fonts.muliRegularHeading3)
            }
            .font(Fonts.muliRegularHeading3)
            .lineSpacing(12)
            .padding()
        }
    }
}

struct MoreInfoPopupView_Previews: PreviewProvider {
    static var previews: some View {
        MoreInfoPopupView()
    }
}
