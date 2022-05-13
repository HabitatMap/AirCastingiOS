// Created by Lunar on 13/05/2022.
//

import SwiftUI
import UIKit
import GoogleMaps

struct ExternalSessionMap: UIViewRepresentable {
    typealias UIViewType = GMSMapView
    var longitude: CLLocationDegrees
    var latitude: CLLocationDegrees
    
    init(longitude: CLLocationDegrees, latitude: CLLocationDegrees) {
        self.longitude = longitude
        self.latitude = latitude
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 15.0)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        
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
