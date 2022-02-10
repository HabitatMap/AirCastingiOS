// Created by Lunar on 07/02/2022.
//

import SwiftUI

final class StringCustomizer {
    static func customizeString(_ s: String, using words: [String], fontWeight: Font.Weight = .bold, color: Color = .aircastingGray, font: Font = .body, makeNewLineAfterCustomized: Bool = false) -> Text {
        
        var descriptionText: Text!
        let separatedText = s.components(separatedBy: " ")
        var newL = false
        var keyWordsSeparated = words.flatMap { $0.components(separatedBy: " ") }
        
        for word in separatedText {
            if keyWordsSeparated.contains(word) {
                if let index = keyWordsSeparated.firstIndex(of: word) {
                    keyWordsSeparated.remove(at: index)
                }
                newL = true
                descriptionText = (descriptionText == nil ? Text(word) : descriptionText + Text(word))
                    .fontWeight(fontWeight)
                    .foregroundColor(color)
                    .font(font)
            } else {
                if newL && makeNewLineAfterCustomized {
                    descriptionText = descriptionText + Text("\n")
                }
                descriptionText = (descriptionText == nil ? Text(word) : descriptionText + Text(word))
                    .fontWeight(.regular)
                    .foregroundColor(.aircastingGray)
                newL = false
            }
            descriptionText = descriptionText + Text(" ")
        }
        return descriptionText
    }
    
}
