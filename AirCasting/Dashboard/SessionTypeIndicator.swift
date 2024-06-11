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
            componentsSeparation(name: &name)
//                .replacingOccurrences(of: ":", with: "-")
//                .components(separatedBy: "-").first!
            
            name = (name == "Builtin") ? "Phone mic" : name
            !stream.contains(name) ? stream.append(name) : nil
        }
        text = stream.joined(separator: ", ")
        return Text("\(sessionType.description) : \(text)")
            .font(Fonts.moderateRegularHeading4)
    }
    
    private func componentsSeparation(name: inout String) {
            // separation is used to nicely handle the case where sensor could be
            // AirBeam2-xxxx or AirBeam2:xxx
            if name.contains(":") {
                name = name.components(separatedBy: ":").first!
            } else {
                name = name.components(separatedBy: "-").first!
            }
        }
}
