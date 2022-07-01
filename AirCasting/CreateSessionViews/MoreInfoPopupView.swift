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
                Text(Strings.MoreInfoPopupView.text_2)
                Text(Strings.MoreInfoPopupView.text_3)
            }
            .font(Fonts.muliRegularHeading3)
            .lineSpacing(12)
            .foregroundColor(.aircastingGray)
            .padding()
        }
    }
}

struct MoreInfoPopupView_Previews: PreviewProvider {
    static var previews: some View {
        MoreInfoPopupView()
    }
}
