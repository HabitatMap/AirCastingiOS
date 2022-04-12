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
            parametersQuestion
            HStack(spacing: 12) {
                ForEach(ParameterType.allCases) { param in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.onParameterTap(with: param)
                        }
                    } label: {
                        Text(param.capitalizedName)
                            .padding([.all], 5)
                    }.buttonStyle(MultiSelectButtonStyle(isSelected: param.capitalizedName == viewModel.getParameter.capitalizedName))
                        .padding(.bottom, 5)
                }
            }
            sensorQuestion
            if viewModel.shoudShowPMChoiceSheet {
                ForEach(PMSensorType.allCases) { sensor in
                    Button {
                        viewModel.onPMSensorTap(with: sensor)
                    } label: {
                        Text(sensor.capitalizedName)
                            .padding([.all], 5)
                    }.buttonStyle(MultiSelectButtonStyle(isSelected: sensor.capitalizedName == viewModel.getSensor.capitalizedName))
                        .padding(.bottom, 5)
                }
            } else {
                ForEach(OzoneSensorType.allCases) { sensor in
                    Button {
                        viewModel.onOzoneSensorTap(with: sensor)
                    } label: {
                        Text(sensor.capitalizedName)
                            .padding([.all], 5)
                    }.buttonStyle(MultiSelectButtonStyle(isSelected: sensor.capitalizedName == viewModel.getSensor.capitalizedName))
                        .padding(.bottom, 5)
                    
                }
            }
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
    
    var parametersQuestion: some View {
        Text(Strings.SearchView.parametersQuestion)
            .padding(.top, 20)
            .font(Fonts.mediumHeading2)
            .foregroundColor(.aircastingDarkGray)
    }
    
    var sensorQuestion: some View {
        Text(Strings.SearchView.sensorQuestion)
            .padding(.top, 20)
            .font(Fonts.mediumHeading2)
            .foregroundColor(.aircastingDarkGray)
    }
    
    var button: some View {
        return NavigationLink(
            destination: SearchMapView(locationName: viewModel.addressName,
                                       locationAddress: viewModel.addresslocation,
                                       parameterType: viewModel.getParameter,
                                       sensorType: viewModel.getSensor),
            label: {
                Text(Strings.Commons.continue)
            })
        .buttonStyle(BlueButtonStyle())
        .disabled(viewModel.continueDisabled)
    }
}
