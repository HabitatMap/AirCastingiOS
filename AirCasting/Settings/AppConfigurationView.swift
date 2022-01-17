// Created by Lunar on 30/11/2021.
//

import SwiftUI
import Resolver

#if DEBUG || BETA
struct AppConfigurationView: View {
    @InjectedObject private var config: FeatureFlagsViewModel
    
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
#endif
