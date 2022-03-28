// Created by Lunar on 23/03/2022.
//

import Foundation

protocol SearchSessionStreamsDownstream {
    func downloadSession(uuid: SessionUUID, completion: @escaping (Result<SearchSession, Error>) -> Void)
}

class SearchSessionStreamsDownstreamMock: SearchSessionStreamsDownstream {
    func downloadSession(uuid: SessionUUID, completion: @escaping (Result<SearchSession, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            completion(.success(.mock))
        }
    }
}
