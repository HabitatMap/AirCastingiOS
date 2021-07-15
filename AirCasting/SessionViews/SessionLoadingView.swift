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
                    .font(Font.moderate(size: 15))
                Text(Strings.LoadingSession.description)
            }
            .font(Font.moderate(size: 13))
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
