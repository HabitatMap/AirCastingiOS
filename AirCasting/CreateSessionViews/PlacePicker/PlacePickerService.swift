// Created by Lunar on 14/02/2022.
//

import Foundation
import GooglePlaces

protocol PlacePickerService {
    func didComplete(using place: GMSPlace)
}
