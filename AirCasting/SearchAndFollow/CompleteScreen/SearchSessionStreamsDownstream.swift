// Created by Lunar on 23/03/2022.
//

import Foundation

//protocol SearchSessionStreamsDownstream {
//    func downloadSession(id: String, completion: @escaping (Result<SearchSession, Error>) -> Void)
//}
//
//class SearchSessionStreamsDownstreamMock: SearchSessionStreamsDownstream {
//    func downloadSession(id: String, completion: @escaping (Result<SearchSession, Error>) -> Void) {
////        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
////            completion(.success(.mock))
////        }
//        SessionDownloadService().downloadSessionWithMeasurements(id: id) { result in
//            switch result {
//            case .success(let data):
//                Log.info("## \(data)")
//                completion(.success(SearchSession.mock))
//            case .failure(let error):
//                Log.info("## \(error)")
//                completion(.failure(error))
//            }
//        }
//    }
//}
