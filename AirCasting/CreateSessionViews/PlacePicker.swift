// Created by Lunar on 11/08/2021.
//

import SwiftUI
import GooglePlaces
import Resolver

struct PlacePicker: UIViewControllerRepresentable {
    @InjectedObject private var tracker: LocationTracker
    @Binding var placePickerDismissed: Bool
    @Environment(\.presentationMode) var presentationMode
    @Binding var address: String

    func makeUIViewController(context: UIViewControllerRepresentableContext<PlacePicker>) -> GMSAutocompleteViewController {
        GMSPlacesClient.provideAPIKey(GOOGLE_PLACES_KEY)
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = context.coordinator

        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) | UInt(GMSPlaceField.coordinate.rawValue))
        autocompleteController.placeFields = fields

        let filter = GMSAutocompleteFilter()
        filter.type = .geocode
        autocompleteController.autocompleteFilter = filter
        return autocompleteController
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func updateUIViewController(_ uiViewController: GMSAutocompleteViewController, context: UIViewControllerRepresentableContext<PlacePicker>) { }

    class Coordinator: NSObject, UINavigationControllerDelegate, GMSAutocompleteViewControllerDelegate {

        var parent: PlacePicker
        
        init(_ parent: PlacePicker) {
            self.parent = parent
        }

        func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
            DispatchQueue.main.async { [self] in
                self.parent.address =  place.name!
                parent.tracker.googleLocation = [PathPoint(location: place.coordinate, measurementTime: DateBuilder.getFakeUTCDate(), measurement: 20.0)]
                parent.placePickerDismissed = true
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }

        func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
            Log.info("Error when fetching location place: \(error.localizedDescription)")
        }

        func wasCancelled(_ viewController: GMSAutocompleteViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }

    }
}
