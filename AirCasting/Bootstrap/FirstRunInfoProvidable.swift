// Created by Lunar on 13/09/2021.
//

import Foundation

protocol FirstRunInfoProvidable {
    var isFirstAppLaunch: Bool { get }
    func registerAppLaunch()
}
