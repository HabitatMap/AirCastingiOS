//
//  Font.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import Foundation
import SwiftUI

extension Font {
    static func muli(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.custom("Muli", fixedSize: size).weight(weight)
    }
    static func moderate(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.custom("Moderat-Trial-Regular", fixedSize: size).weight(weight)
    }
}
