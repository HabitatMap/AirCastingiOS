// Created by Lunar on 04/03/2022.
//

import Foundation

class StaticSingleStreamViewModel: ObservableObject {
    let streamId: Int
    let streamName: String
    let value: Double
    
    init(streamId: Int, streamName: String, value: Double) {
        self.streamName = Self.showStreamName(streamName)
        self.value = value
        self.streamId = streamId
    }
    
    
    private static func showStreamName(_ streamName: String) -> String {
        streamName
            .replacingOccurrences(of: ":", with: "-")
            .drop { $0 != "-" }
            .replacingOccurrences(of: "-", with: "")
    }
}
