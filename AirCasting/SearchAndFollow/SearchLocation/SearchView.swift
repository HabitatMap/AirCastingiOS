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
                particularMatterButton
                ozoneButton
            }
            sensorQuestion
            if viewModel.shoudShowPMChoiceSheet {
                    OpenAQ
                    .padding(.bottom, 5)
                    ABP325
                    .padding(.bottom, 5)
                    ABP225
            } else {
                OzoneSensor
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
    
    var ozoneButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3), {
                viewModel.onOzoneButtonTap()
            })
        } label: {
            Text(Strings.SearchView.ozoneText)
                .padding([.all], 5)
        }.buttonStyle(MultiSelectButtonStyle(isSelected: viewModel.isOzone))
    }
    
    var particularMatterButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3), {
                viewModel.onPMButtonTap()
            })
        } label: {
            Text(Strings.SearchView.particularMatterText)
                .padding([.all], 5)
        }.buttonStyle(MultiSelectButtonStyle(isSelected: viewModel.isPM))
    }
    
    var ABP325: some View {
        Button {
            viewModel.onAB325ButtonTap()
        } label: {
            Text(Strings.SearchView.AirBeam325)
                .padding([.all], 5)
        }.buttonStyle(MultiSelectButtonStyle(isSelected: viewModel.isAB325))
    }
    
    var ABP225: some View {
        Button {
            viewModel.onAB225ButtonTap()
        } label: {
            Text(Strings.SearchView.AirBeam225)
                .padding([.all], 5)
        }.buttonStyle(MultiSelectButtonStyle(isSelected: viewModel.isAB225))
    }
    
    var OpenAQ: some View {
        Button {
            viewModel.onOpenAQButtonTap()
        } label: {
            Text(Strings.SearchView.openAQ)
                .padding([.all], 5)
        }.buttonStyle(MultiSelectButtonStyle(isSelected: viewModel.isOpenAQ))
    }
    
    var OzoneSensor: some View {
        Button {
            viewModel.onOzoneSensorButtonTap()
        } label: {
            Text(Strings.SearchView.openAQOzone)
                .padding([.all], 5)
        }.buttonStyle(MultiSelectButtonStyle(isSelected: viewModel.isOzoneSensor))
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
