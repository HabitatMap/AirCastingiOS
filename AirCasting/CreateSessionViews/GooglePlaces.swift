// Created by Lunar on 11/08/2021.
//

import Foundation
import UIKit
import SwiftUI
import GooglePlaces


struct PlacePicker: UIViewControllerRepresentable {

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    @Environment(\.presentationMode) var presentationMode
    @Binding var address: String
    @Binding var coordinates: CLLocationCoordinate2D

    func makeUIViewController(context: UIViewControllerRepresentableContext<PlacePicker>) -> GMSAutocompleteViewController {
        GMSPlacesClient.provideAPIKey(GOOGLE_PLACES_KEY)
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = context.coordinator

        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) |
                                                    UInt(GMSPlaceField.placeID.rawValue))
        autocompleteController.placeFields = fields

        let filter = GMSAutocompleteFilter()
        filter.type = .address
        autocompleteController.autocompleteFilter = filter
        return autocompleteController
    }

    func updateUIViewController(_ uiViewController: GMSAutocompleteViewController, context: UIViewControllerRepresentableContext<PlacePicker>) {
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, GMSAutocompleteViewControllerDelegate {

        var parent: PlacePicker
        
        init(_ parent: PlacePicker) {
            self.parent = parent
        }

        func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
            DispatchQueue.main.async {
                print(place.description.description as Any)
                self.parent.address =  place.name!
                self.parent.coordinates = place.coordinate
                print("COORDINATES: \(place.coordinate)")
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }

        func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
            print("Error: ", error.localizedDescription)
        }

        func wasCancelled(_ viewController: GMSAutocompleteViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }

    }
}
