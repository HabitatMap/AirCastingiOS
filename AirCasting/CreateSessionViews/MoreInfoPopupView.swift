//
//  MoreInfoPopupView.swift
//  AirCasting
//
//  Created by Lunar on 18/03/2021.
//

import SwiftUI

struct MoreInfoPopupView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text(Strings.MoreInfoPopupView.text_1)
                .font(Fonts.boldTitle2)
                .foregroundColor(.accentColor)
            StringCustomizer.customizeString(Strings.MoreInfoPopupView.text_2,
                                             using: [Strings.MoreInfoPopupView.mobile],
                                             color: .accentColor,
                                             standardFont: Fonts.muliHeading2)
            StringCustomizer.customizeString(Strings.MoreInfoPopupView.text_3,
                                             using: [Strings.MoreInfoPopupView.fixed],
                                             color: .accentColor,
                                             standardFont: Fonts.muliHeading2)
        }
        .font(Fonts.muliHeading2)
        .lineSpacing(12)
        .foregroundColor(.aircastingGray)
        .padding()
    }
}

struct MoreInfoPopupView_Previews: PreviewProvider {
    static var previews: some View {
        MoreInfoPopupView()
    }
}
