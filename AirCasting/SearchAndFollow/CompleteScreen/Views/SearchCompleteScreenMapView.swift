// Created by Lunar on 25/02/2022.
//

import SwiftUI
import UIKit
import GoogleMaps

struct SearchCompleteScreenMapView: UIViewRepresentable {
    typealias UIViewType = GMSMapView
    var longitude: CLLocationDegrees
    var latitude: CLLocationDegrees
    
    init(longitude: CLLocationDegrees, latitude: CLLocationDegrees) {
        self.longitude = longitude
        self.latitude = latitude
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        // Zoom:
        // 1. World
        // 5. Continent
        // 10. Cities
        // 15. Streets
        // 20. Buildings
        
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 15.0)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        if UserDefaults.standard.bool(forKey: "satteliteMapKey") { mapView.mapType = .satellite }
        
        do {
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                Log.error("Unable to find style.json")
            }
        } catch {
            Log.error("One or more of the map styles failed to load. \(error)")
        }
        
        let mainPoint = UIImage.imageWithColor(color: UIColor.accentColor, size: CGSize(width: Constants.Map.dotWidth, height: Constants.Map.dotHeight))
        
        let dot = GMSMarker()
        dot.icon = mainPoint
        dot.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        dot.map = mapView
        
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        //
    }
}
