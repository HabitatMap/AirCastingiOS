// Created by Lunar on 07/07/2022.
//

import SwiftUI

class ColorSchemeMode: ObservableObject {
    enum Mode {
        case light
        case dark
    }
    
    @Published var currentMode: Mode = .light
    
    func changeDarkMode(state: Bool){
        currentMode = state == true ? .dark : .light
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first!.overrideUserInterfaceStyle = state ? .dark : .light
    }
}

