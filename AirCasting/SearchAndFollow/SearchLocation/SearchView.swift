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
                ForEach(viewModel.MeasurementTypes) { param in
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.onParameterTap(with: param.name)
                        }
                    } label: {
                        Text(param.name)
                            .padding([.all], 5)
                    }.buttonStyle(MultiSelectButtonStyle(isSelected: param.isSelected))
                        .padding(.bottom, 5)
                }
            }
            sensorQuestion
            switch viewModel.getParameter {
            case .particulateMatter:
                HStack(spacing: 12) {
                    ForEach(viewModel.PMSensorTypes) { sensor in
                        Button {
                            viewModel.onPMSensorTap(with: sensor.name)
                        } label: {
                            Text(sensor.name)
                                .padding([.all], 5)
                        }.buttonStyle(MultiSelectButtonStyle(isSelected: sensor.isSelected))
                            .padding(.bottom, 5)
                    }
                }
            case .ozone:
                HStack(spacing: 12) {
                    ForEach(viewModel.OzoneSensorTypes) { sensor in
                        Button {
                            viewModel.onOzoneSensorTap(with: sensor.name)
                        } label: {
                            Text(sensor.name)
                                .padding([.all], 5)
                        }.buttonStyle(MultiSelectButtonStyle(isSelected: sensor.isSelected))
                            .padding(.bottom, 5)
                    }
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
