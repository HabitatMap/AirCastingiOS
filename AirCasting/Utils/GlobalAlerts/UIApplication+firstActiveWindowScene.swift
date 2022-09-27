// Created by Lunar on 18/08/2022.
//

import UIKit

extension UIApplication {
    public static var firstActiveWindowScene: UIWindowScene? {
        return UIApplication.shared
                        .connectedScenes
                        .filter { $0.activationState == .foregroundActive }
                        .first as? UIWindowScene
    }
}
