// Created by Lunar on 14/02/2022.
//

import SwiftUI
import AirCastingStyling
import CoreLocation

struct SearchView: View {
    @StateObject var viewModel: SearchViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var exploreSessionsButton: ExploreSessionsButton
    @Binding var isSearchAndFollowLinkActive: Bool
    
    init(isSearchAndFollowLinkActive: Binding<Bool>) {
        _viewModel = .init(wrappedValue: SearchViewModel())
        _isSearchAndFollowLinkActive = .init(projectedValue: isSearchAndFollowLinkActive)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            title
            textField
            
            parametersQuestion

            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.measurementTypes) { param in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.onParameterTap(with: param.name)
                        }
                    } label: {
                        Text(param.name)
                            .fixedSize()
                            .lineLimit(1)

                            .padding(5)
                    }.buttonStyle(MultiSelectButtonStyle(isSelected: param.isSelected))
                        .padding(.bottom, 5)
                }
            }
            sensorQuestion
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.sensorTypes) { sensor in
                    Button {
                        viewModel.onSensorTap(with: sensor.name)
                    } label: {
                        Text(sensor.name)
                            .padding(5)
                    }.buttonStyle(MultiSelectButtonStyle(isSelected: sensor.isSelected))
                        .padding(.bottom, 5)
                }
            }
            Spacer()
            button
        }
        .padding()
        .background(Color.aircastingBackground.ignoresSafeArea())
        .onAppear(perform: {
            viewModel.viewInitialized { presentationMode.wrappedValue.dismiss() }
            exploreSessionsButton.exploreSessionsButtonTapped = false
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
            .font(Fonts.muliSemiboldTitle1)
            .padding(.bottom, 20)
    }
    
    var textField: some View {
        createTextfield(placeholder: Strings.SearchView.placeholder,
                        binding: .init(get: {
            viewModel.addressName
        }, set: { new in
            viewModel.locationNameInteracted(with: new)
        }))
        .font(Fonts.moderateRegularHeading2)
        .disabled(true)
        .onTapGesture { viewModel.textFieldTapped() }
    }
    
    var parametersQuestion: some View {
        Text(Strings.SearchView.parametersQuestion)
            .padding(.top, 20)
            .font(Fonts.muliMediumHeading2)
            .foregroundColor(.aircastingDarkGray)
    }
    
    var sensorQuestion: some View {
        Text(Strings.SearchView.sensorQuestion)
            .padding(.top, 20)
            .font(Fonts.muliMediumHeading2)
            .foregroundColor(.aircastingDarkGray)
    }
    
    var button: some View {
        return NavigationLink(
            destination: SearchMapView(locationName: viewModel.addressName,
                                       locationAddress: viewModel.addresslocation,
                                       parameterType: viewModel.selectedParameter ?? .particulateMatter,
                                       sensorType: viewModel.selectedSensor ?? .AirBeam, isSearchAndFollowLinkActive: $isSearchAndFollowLinkActive),
            label: {
                Text(Strings.Commons.continue)
            })
        .buttonStyle(BlueButtonStyle())
        .disabled(viewModel.continueDisabled)
    }
}


struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(isSearchAndFollowLinkActive: .constant(true))
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
            .previewDisplayName("Default preview")
    }
}
