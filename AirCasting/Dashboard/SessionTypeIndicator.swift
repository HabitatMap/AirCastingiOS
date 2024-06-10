// Created by Lunar on 03/02/2022.
//

import SwiftUI

struct SessionTypeIndicator: View {
    let sessionType: SessionType
    let streamSensorNames: [String]
    
    var body: some View {
        var stream = [String]()
        var text = ""
        guard !streamSensorNames.isEmpty else { return Text("") }
        
        streamSensorNames.forEach { sensorName in
            var name = sensorName
                .replacingOccurrences(of: ":", with: "-")
                .components(separatedBy: "-").first!
            
            name = (name == "Builtin") ? "Phone mic" : name
            !stream.contains(name) ? stream.append(name) : nil
        }
        text = stream.joined(separator: ", ")
        return Text("\(sessionType.description) : \(text)")
            .font(Fonts.moderateRegularHeading4)
    }
}
