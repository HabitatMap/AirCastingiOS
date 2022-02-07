// Created by Lunar on 07/02/2022.
//

import SwiftUI

final class StringCustomizer {
    static func customizeString(_ s: String, using words: [String], fontWeight: Font.Weight = .bold, color: Color = .aircastingGray, font: Font = .body, makeNewLineAfterCustomized: Bool = false) -> Text {
        
        var descriptionText: Text!
        let separatedText = s.components(separatedBy: " ")
        var total = [String]()
        var newL = false
        
        words.forEach { wd in
            let sp = wd.components(separatedBy: " ")
            sp.forEach({ total.append( $0 ) })
        }
        
        for w in separatedText {
            if total.contains(w) {
                if let index = total.firstIndex(of: w) {
                    total.remove(at: index)
                }
                newL = true
                descriptionText = (descriptionText == nil ? Text(w) : descriptionText + Text(w))
                    .fontWeight(fontWeight)
                    .foregroundColor(color)
                    .font(font)
            } else {
                if newL && makeNewLineAfterCustomized {
                    descriptionText = descriptionText + Text("\n")
                }
                descriptionText = (descriptionText == nil ? Text(w) : descriptionText + Text(w))
                    .fontWeight(.regular)
                    .foregroundColor(.aircastingGray)
                newL = false
            }
            descriptionText = descriptionText + Text(" ")
        }
        return descriptionText
    }
    
}
