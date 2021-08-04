//
//  File.swift
//  
//
//  Created by Lunar on 17/06/2021.
//

import SwiftUI

extension Font {
    
    public static func muli(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            return Font.custom("Muli", fixedSize: size).weight(weight)
    }
    
    public static func moderate(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.custom("Moderat-Trial-Regular", fixedSize: size).weight(weight)
    }
}
