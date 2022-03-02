// Created by Lunar on 14/02/2022.
//

import SwiftUI
import AirCastingStyling

struct SearchView: View {
    @StateObject var viewModel: SearchViewModel
    @Binding var creatingSessionFlowContinues: Bool
    @EnvironmentObject private var exploreSessionsButton: ExploreSessionsButton
    
    init(creatingSessionFlowContinues: Binding<Bool>) {
        _viewModel = .init(wrappedValue: SearchViewModel())
        self._creatingSessionFlowContinues = creatingSessionFlowContinues
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            title
            textField
            Spacer()
            button
        }.padding()
        .onAppear(perform: { exploreSessionsButton.exploreSessionsButtonTapped = false })
        .sheet(isPresented: $viewModel.isLocationPopupPresented) {
            PlacePicker(service: SearchPickerService(address: .init(get: {
                viewModel.location
            }, set: { newLocation in
                viewModel.updateLocation(using: newLocation)
            })))
        }
    }
}

// MARK: - Private View Components
private extension SearchView {
    var title: some View {
        Text(Strings.SearchView.title)
            .foregroundColor(.aircastingDarkGray)
            .font(Font.muli(size: 24, weight: .medium))
            .padding(.bottom, 20)
    }
    
    var textField: some View {
        createTextfield(placeholder: Strings.SearchView.placeholder,
                        binding: .init(get: {
            viewModel.location
        }, set: { newLocation in
            viewModel.updateLocation(using: newLocation)
        }))
            .disabled(true)
            .onTapGesture { viewModel.textFieldTapped() }
    }
    
    var button: some View {
        Button {
            Log.info("Continuing to next screen")
        } label: {
            Text(Strings.Commons.continue)
        }.buttonStyle(BlueButtonStyle())
    }
}
