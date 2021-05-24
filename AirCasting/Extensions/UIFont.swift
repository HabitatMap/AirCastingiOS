// Created by Lunar on 24/05/2021.
//

import Foundation
import UIKit

extension UIFont {

    static func muli(size: CGFloat) -> UIFont {
        return UIFont(name: "Muli", size: size) ?? UIFont.systemFont(ofSize: size, weight: .medium)
    }
}
