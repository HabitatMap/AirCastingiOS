// Created by Lunar on 14/02/2022.
//

import SwiftUI
import AirCastingStyling


struct SearchView: View {
    @StateObject var viewModel: SearchViewModel
    @Binding var creatingSessionFlowContinues: Bool
    
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
        .sheet(isPresented: $viewModel.isLocationPopupPresented) {
            PlacePicker(service: SearchPickerService(address: $viewModel.location))
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
                        binding: $viewModel.location)
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
