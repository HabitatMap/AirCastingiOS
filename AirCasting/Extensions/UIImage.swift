// Created by Lunar on 19/10/2021.
//

import UIKit

extension UIImage {
    class func imageWithColor(color: UIColor, size: CGSize = CGSize(width: 10, height: 10)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            let roundedImage = image.withRoundedCorners(radius: 12)
            UIGraphicsEndImageContext()
            return roundedImage!
        } else {
            return UIImage()
        }
    }
}

extension UIImage {
    public func withRoundedCorners(radius: CGFloat? = nil) -> UIImage? {
        let maxRadius = min(size.width, size.height) / 2
        let cornerRadius: CGFloat
        if let radius = radius, radius > 0 && radius <= maxRadius {
            cornerRadius = radius
        } else {
            cornerRadius = maxRadius
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
