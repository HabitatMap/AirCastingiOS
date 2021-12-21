// Created by Lunar on 16/12/2021.
//

import Foundation
import SwiftUI

protocol SessionHeaderViewModel: ObservableObject {
    var sheetDestination: SheetDestination? { get set }
//    func sheetView() -> AnyView?
}

enum SheetDestination: Identifiable {
    case delete
    case share
    
    var id: Int {
            hashValue
        }
}

class DefaultSessionHeaderViewModel: SessionHeaderViewModel {
    @Published var showSheet: Bool = false
    @Published var sheetDestination: SheetDestination? = nil
    
//    func sheetView() -> AnyView? {
//        switch sheetDestination {
//        case .none:
//            return nil
//        case .share:
//            return ShareSessionView(viewModel: DefaultShareSessionViewModel(), showSharingModal: Binding<Bool>(get: {self.showSheet}, set: {newValue in self.showSheet = newValue}))
//        case .delete:
//            return ShareSessionView(viewModel: DefaultShareSessionViewModel(), showSharingModal: Binding<Bool>(get: {self.showSheet}, set: {newValue in self.showSheet = newValue}))
//        }
//    }
    
    
}
