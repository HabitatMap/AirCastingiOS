//
//  ContentView.swift
//  NewMap
//
//  Created by Pawel Gil on 27/09/2022.
//

import SwiftUI
import CoreLocation

class MapDotColorProvider: ObservableObject {
    @Published var color: Color = .green
    private let colors: [Color] = [.blue, .green, .yellow, .orange, .red]
    
    init() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let newColor = self.colors[Int.random(in: 0..<self.colors.count)]
            self.color = newColor
        }
    }
}

let tracker = DummyTracker()

struct ContentView: View {
    @StateObject var colorProvider = MapDotColorProvider()
    @StateObject var vm = MikroViewModel()
    
    var body: some View {
        _MapView(path: [.krakow, .gdansk, .warsaw],
                 type: .terrain,
                 trackingStyle: .user,
                 userIndicatorStyle: .custom(color: colorProvider.color),
                 userTracker: tracker,
                 markers: vm.markers)
    }
    
    
}

class MikroViewModel: ObservableObject {
    @Published var markers: [_MapView.Marker] = MikroViewModel.allMarkers
    
    static let allMarkers: [_MapView.Marker] = [
        .init(id: 0, image: .init(named: "marker")!, location: CLLocation.warsaw, handler: {
            print("## WWA")
        }),
        .init(id: 1, image: .init(named: "marker")!, location: CLLocation.gdansk, handler: {
            print("## GDN")
        }),
        .init(id: 2, image: .init(named: "marker")!, location: CLLocation.krakow.movedBy(latitudinalMeters: 100, longitudinalMeters: 100), handler: {
            print("## KRK")
        }),
    ]
    
    init() {
//        print("## Starting markers randomizer")
//        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
//            let idx = (0...2).randomElement()!
//            print("## New marker randomized \(idx)")
//            self.markers = [Self.allMarkers[idx]]
//        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension _MapView.PathPoint {
    static var gdansk: Self { .init(lat: CLLocation.gdansk.coordinate.latitude, long: CLLocation.gdansk.coordinate.longitude) }
    static var warsaw: Self { .init(lat: CLLocation.warsaw.coordinate.latitude, long: CLLocation.warsaw.coordinate.longitude) }
    static var krakow: Self { .init(lat: CLLocation.krakow.coordinate.latitude, long: CLLocation.krakow.coordinate.longitude) }
    static var applePark: Self { .init(lat: CLLocation.applePark.coordinate.latitude, long: CLLocation.applePark.coordinate.longitude) }
}

extension CLLocation {
    static var gdansk: CLLocation { CLLocation(latitude: 54.35, longitude: 18.64) }
    static var warsaw: CLLocation { CLLocation(latitude: 52.22, longitude: 21.01) }
    static var krakow: CLLocation { CLLocation(latitude: 50.06, longitude: 19.94) }
    static var applePark: CLLocation { CLLocation(latitude: 37.33, longitude: -122.00) }
}

import MapKit

extension CLLocation {
    func movedBy(latitudinalMeters: CLLocationDistance, longitudinalMeters: CLLocationDistance) -> CLLocation {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: abs(latitudinalMeters), longitudinalMeters: abs(longitudinalMeters))

        let latitudeDelta = region.span.latitudeDelta
        let longitudeDelta = region.span.longitudeDelta

        let latitudialSign = CLLocationDistance(latitudinalMeters.sign == .minus ? -1 : 1)
        let longitudialSign = CLLocationDistance(longitudinalMeters.sign == .minus ? -1 : 1)

        let newLatitude = coordinate.latitude + latitudialSign * latitudeDelta
        let newLongitude = coordinate.longitude + longitudialSign * longitudeDelta

        let newCoordinate = CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)

        let newLocation = CLLocation(coordinate: newCoordinate, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: course, speed: speed, timestamp: Date())

        return newLocation
    }
}
