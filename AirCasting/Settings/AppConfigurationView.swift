// Created by Lunar on 30/11/2021.
//

import SwiftUI

struct AppConfigurationView: View {
    @StateObject private var config: FeatureFlagsViewModel = .shared
    
    var body: some View {
        List(FeatureFlag.allCases, id: \.name) { feature in
            HStack {
                Toggle(feature.name, isOn: Binding<Bool>(get: {
                    config.enabledFeatures.contains(feature)
                }, set: { isOn in
                    config.overrideFeature(feature, with: isOn)
                }))
            }
        }
    }
}
