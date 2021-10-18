// Created by Lunar on 15/10/2021.
//

import Foundation
import UIKit
import SwiftUI

extension UIImage {
    static let MainTabBarShadow = UIImage.gradientImageWithBounds(
        bounds: CGRect(x: 0, y: 0, width: UIScreen.main.scale, height: 5),
        colors: [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.1).cgColor
        ]
    )
    
    static func gradientImageWithBounds(bounds: CGRect, colors: [CGColor]) -> UIImage {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors
        
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
