// Created by Lunar on 07/03/2022.
//

import Foundation
import SwiftUI

struct BottomCardView: View {
    @StateObject var viewModel: BottomCardViewModel
    private var onMarkerChangeAction: ((Int) -> ())? = nil
    
    init(id: Int, title: String, startTime: String, endTime: String, latitude: Double, longitude: Double) {
        _viewModel = .init(wrappedValue: .init(id: id, title: title, startTime: startTime, endTime: endTime, latitude: latitude, longitude: longitude))
    }
    
    var body: some View {
        sessionCard
    }
    
    var sessionCard: some View {
        Button {
            viewModel.sessionCardTapped()
            onMarkerChangeAction?(viewModel.dataModel.id)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(viewModel.dataModel.title)
                    .foregroundColor(.darkBlue)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0.01)
                dataAndTime
                    .font(Fonts.regularHeading4)
                    .foregroundColor(.aircastingGray)
                    .minimumScaleFactor(0.1)
                    .scaledToFit()
            }
        }
        .sheet(isPresented: .init(get: {
            viewModel.getIsModalScreenPresented()
        }, set: { value in
            viewModel.setIsModalScreenPresented(using: value)
        }), content: { viewModel.initCompleteScreen() })
        .frame(width: 200, alignment: .leading)
        .padding([.all], 10)
        .background(
            Group {
                Color.white
                    .shadow(color: .sessionCardShadow, radius: 9, x: 0, y: 1)
            }
        )
    }
}

// MARK: - Private View Components
private extension BottomCardView {
    var dataAndTime: some View {
        Text(viewModel.adaptTimeAndDate())
    }
}

extension BottomCardView {
    func onMarkerChange(action: @escaping (_ pointer: Int) -> ()) -> Self {
        var newSelf = self
        newSelf.onMarkerChangeAction = action
        return newSelf
    }
}
