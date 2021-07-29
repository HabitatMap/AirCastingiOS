// Created by Lunar on 29/07/2021.
//

import Foundation

protocol SessionCartFollowing {
    func makeFollowing(for session: SessionEntity)
    func makeNotFollowing(for session: SessionEntity)
}
