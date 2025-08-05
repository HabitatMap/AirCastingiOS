// Created by Lunar on 4.08.25.
//

import SwiftUI
import AirCastingStyling

struct ProgressFlowAB: View {
    let title: String
    let message: String
    let progress: Float
    let abImage: any View
    
    let continueButtonOnClickDestination: (any View)?
    let continueButtonOnClick: (@MainActor () -> Void)?
    
    init(progress: Float, abImage: any View, title: String, message: String,  continueButtonOnClickDestination: (any View)? = nil) {
        self.progress = progress
        self.title = title
        self.message = message
        self.abImage = abImage
        self.continueButtonOnClick = nil
        self.continueButtonOnClickDestination = continueButtonOnClickDestination
    }
    
    init(progress: Float, airbeamImageAsset: String, title: String, message: String, continueButtonOnClickDestination: (any View)? = nil) {
        self.progress = progress
        self.title = title
        self.message = message
        self.abImage = image(airbeamImageAsset)
        self.continueButtonOnClick = nil
        self.continueButtonOnClickDestination = continueButtonOnClickDestination
    }
    
    init(progress: Float, airbeamImageAsset: String, title: String, message: String, continueButtonOnClick: @escaping @MainActor () -> Void) {
        self.progress = progress
        self.title = title
        self.message = message
        self.abImage = image(airbeamImageAsset)
        self.continueButtonOnClickDestination = nil
        self.continueButtonOnClick = continueButtonOnClick
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            ProgressView(value: progress)
                .padding(.bottom, 50)
            AnyView(abImage)
                .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                    .frame(maxWidth: .infinity, alignment: .leading)
                messageLabel
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top)
            .frame(maxWidth: .infinity)
            Spacer()
            if let continueButtonOnClickDestination {
                NavigationLink(
                    destination: AnyView(continueButtonOnClickDestination),
                    label: {
                        Text(Strings.Commons.continue)
                            .font(Fonts.muliBoldHeading1)
                            .frame(maxWidth: .infinity)
                    })
                .buttonStyle(BlueButtonStyle())
                
            } else if let continueButtonOnClick {
                Button(action: continueButtonOnClick) {
                    Text(Strings.Commons.continue)
                        .font(Fonts.muliBoldHeading1)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BlueButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.aircastingBackground.ignoresSafeArea())
    }
    
    var titleLabel: some View {
        Text(title)
            .font(Fonts.moderateBoldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(message)
            .font(Fonts.moderateRegularHeading1)
            .foregroundColor(.aircastingGray)
    }
}

private func image(_ imageAsset: String) -> any View {
    Image(imageAsset)
        .aspectRatio(contentMode: .fit)
}

#Preview("AB Loading") {
    ProgressFlowAB(progress: 0.4, abImage: ABCircleAndLoader(), title: Strings.SDSyncRootView.title, message: Strings.SDSyncRootView.message)
}

#Preview("AB Ready") {
    ProgressFlowAB(progress: 0.4, airbeamImageAsset: "4-connected", title: Strings.SDSyncRootView.title, message: Strings.SDSyncRootView.message, continueButtonOnClickDestination: Text("test"))
}
