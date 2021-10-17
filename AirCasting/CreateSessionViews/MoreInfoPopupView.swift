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
                .font(Fonts.MoreInfoPopupView.first)
                .foregroundColor(.accentColor)
            Text(Strings.MoreInfoPopupView.text_2)
            Text(Strings.MoreInfoPopupView.text_3)
        }
        .font(Fonts.MoreInfoPopupView.second)
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
