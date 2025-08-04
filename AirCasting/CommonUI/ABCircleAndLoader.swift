// Created by Lunar on 4.08.25.
//

import SwiftUI

struct ABCircleAndLoader: View {
    let airbeamImage: String
    
    init(airbeamImage: String = "airbeam") {
        self.airbeamImage = airbeamImage
    }
    
    var body: some View {
        syncImage
            .overlay(
                loader
                    .padding(28),
                alignment: .bottomTrailing
            )
    }
    
    var loader: some View {
        ZStack {
            Color.accentColor
                .frame(width: Constants.Loader.size, height: Constants.Loader.size)
                .clipShape(Circle())
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                .scaleEffect(2)
        }
    }
    
    var syncImage: some View {
        Image(airbeamImage)
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    ABCircleAndLoader()
}
