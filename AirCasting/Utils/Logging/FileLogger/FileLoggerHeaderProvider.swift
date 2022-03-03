// Created by Lunar on 06/02/2022.
//

import Foundation

protocol FileLoggerHeaderProvider {
    var headerText: String { get }
}

class AirCastingLogoFileLoggerHeaderProvider: FileLoggerHeaderProvider {
    private static let textMargin = 28
    private static let headerTemplate =
"""
                                                                                
                            55GB##&&&@&
                        5PB&@@@@&#BBGGP
                      P#@@@&BP5      55
                   5B&@@#G5   PGB#&@@@&
                  G@@@B5  5G#@@@&#BGGPP
                P&@@B5J P#@@&BP J
               G@@&P  P&@@#P J 5PB#&@@&
              G@@#   B@@#P J G#@@@&BGGP
             G@@#   #@@B   G&@@#P5
            5&@@5  #@@G   B@@#5
            G@@B  P@@#   B@@B
            #@@P  #@@P  P@@&          G&&&&&&G
            B##5  B##5  P##G         P@@@@@@@@5
                                    5&@@@@@@@@&
                                    #@@@@GB@@@@B
                                   B@@@@B  #@@@@G
                                  P@@@@&5  5@@@@@5
                                 5&@@@@P    G@@@@&
                                 #@@@@B      #@@@@B
                                B@@@@@&&&&&&&&@@@@@G
                               P@@@@@@@@@@@@@@@@@@@@5
                              5&@@@@G5555555555B@@@@&
                              #@@@@#            &@@@@B
                             B@@@@&5            P@@@@@G
                             PPPPP5              PPPPPP
"""
    
    let headerText: String
    
    init(logVersion: String, created: String, device: String, os: String) {
        headerText = Self.headerTemplate
        + Self.blankLine()
        + Self.textLine("AirCasting file log v\(logVersion)")
        + Self.textLine("Created: \(created)")
        + Self.textLine("Device: \(device)")
        + Self.textLine("OS: \(os)")
        + Self.blankLine(fill: "-", fillLength: 80)
    }
    
    private static func blankLine(fill: String = "", fillLength: Int = 0) -> String {
        "\n"+String(repeating: fill, count: fillLength)
    }
    
    private static func textLine(_ text: String) -> String {
        let margin = String(repeating: " ", count: textMargin)
        return "\n"+margin+text
    }
}

