// Created by Lunar on 27/07/2022.
//

import SwiftUI
import GoogleMaps

protocol GoogleMapCore {
    func apllyStylying(to mapView: GMSMapView)
}

struct GoogleMapCoreDefault: GoogleMapCore {
    @Environment(\.colorScheme) var colorScheme
    
    func apllyStylying(to mapView: GMSMapView) {
        do {
            if let styleURL = Bundle.main.url(forResource: colorScheme == .light ? "style" : "darkStyle", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                Log.error("Unable to find style.json")
            }
        } catch {
            Log.error("One or more of the map styles failed to load. \(error)")
        }
    }
}
