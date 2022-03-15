// Created by Lunar on 14/02/2022.
//

import SwiftUI
import AirCastingStyling
import CoreLocation

struct SearchView: View {
    @StateObject var viewModel: SearchViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var exploreSessionsButton: ExploreSessionsButton
    
    init() {
        _viewModel = .init(wrappedValue: SearchViewModel())
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            title
            textField
            Spacer()
            button
        }.padding()
            .onAppear(perform: {
                viewModel.viewInitialized {
                    presentationMode.wrappedValue.dismiss()
                    exploreSessionsButton.exploreSessionsButtonTapped = false
                }
            })
            .alert(item: $viewModel.alert, content: { $0.makeAlert() })
            .sheet(isPresented: $viewModel.isLocationPopupPresented) {
                PlacePicker(service: SearchPickerService(addressName: .init(get: {
                    viewModel.addressName
                }, set: { new in
                    viewModel.locationNameInteracted(with: new)
                }), addressLocation: .init(get: {
                    viewModel.addresslocation
                }, set: { new in
                    viewModel.locationAddressInteracted(with: new)
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
            viewModel.addressName
        }, set: { new in
            viewModel.locationNameInteracted(with: new)
        }))
            .disabled(true)
            .onTapGesture { viewModel.textFieldTapped() }
    }
    
    var button: some View {
        return NavigationLink(
            destination: SearchMapView(locationName: viewModel.addressName,
                                       locationAddress: viewModel.addresslocation,
                                       measurementType: "particular matter"),
            label: {
                Text(Strings.Commons.continue)
            })
            .buttonStyle(BlueButtonStyle())
            .disabled(viewModel.continueDisabled)
    }
}
