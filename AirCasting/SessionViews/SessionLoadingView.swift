// Created by Lunar on 24/06/2021.
//

import SwiftUI

struct SessionLoadingView: View {
    var body: some View {
        HStack {
            Image("ABLoading")
                .resizable()
                .frame(width: 60, height: 60)
            VStack(alignment: .leading) {
                Text(Strings.LoadingSession.title)
                Text(Strings.LoadingSession.description)
            }
            .font(Fonts.regularHeading4)
            .lineSpacing(5)
            .foregroundColor(.darkBlue)
        }
    }
}

#if DEBUG
struct SessionLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        SessionLoadingView()
    }
}
#endif
