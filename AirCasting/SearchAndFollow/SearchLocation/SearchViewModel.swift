// Created by Lunar on 14/02/2022.
//

import Foundation

class SearchViewModel: ObservableObject {
    
    @Published var isLocationPopupPresented = false
    @Published var location = ""
    
    func textFieldTapped() { isLocationPopupPresented.toggle() }
    
    func updateLocation(using newLocation: String) { location = newLocation}
}
