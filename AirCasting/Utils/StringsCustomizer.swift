// Created by Lunar on 07/02/2022.
//

import SwiftUI

final class StringCustomizer {
    static func customizeString(_ s: String, using words: [String], fontWeight: Font.Weight = .bold, color: Color = .aircastingGray, font: Font = .body, makeNewLineAfterCustomized: Bool = false) -> Text {
        
        var customizedText: Text!
        let separatedText = s.components(separatedBy: " ")
        var newLine = false
        var separatedKeyWords = words.flatMap { $0.components(separatedBy: " ") }
        
        separatedText.forEach { word in
            if separatedKeyWords.contains(word) {
                removeUsedWord(separatedKeyWords: &separatedKeyWords, word: word)
                newLine = true
                customizedText = appended(word: word, to: customizedText)
                    .fontWeight(fontWeight)
                    .foregroundColor(color)
                    .font(font)
            } else {
                customizedText = shouldAddEmptyLine(after: customizedText,
                                                    (newLine && makeNewLineAfterCustomized))
                customizedText = appended(word: word, to: customizedText)
                    .fontWeight(.regular)
                    .foregroundColor(.aircastingGray)
                newLine = false
            }
            customizedText = addSpace(after: customizedText)
        }
        return customizedText
    }
    
    //MARK: - Private
    private static func removeUsedWord(separatedKeyWords: inout [String], word: String) {
        if let index = separatedKeyWords.firstIndex(of: word) {
            separatedKeyWords.remove(at: index)
        }
    }
    
    private static func addSpace(after text: Text) -> Text {
        text + Text(" ")
    }
    
    private static func appended(word: String, to text: Text?) -> Text {
        return (text == nil ? Text(word) : text! + Text(word))
    }
    
    private static func shouldAddEmptyLine(after text: Text, _ should: Bool) -> Text {
        guard should else {
            return text
        }
        return addNewEmptyLine(after: text)
    }
    
    private static func addNewEmptyLine(after text: Text) -> Text {
        text + Text("\n")
    }
    
}
