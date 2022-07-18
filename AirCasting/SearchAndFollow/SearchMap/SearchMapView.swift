// Created by Lunar on 16/02/2022.
//

import CoreLocation
import Foundation
import SwiftUI
import AirCastingStyling
import Resolver

struct SearchMapView: View {
    @InjectedObject private var userSettings: UserSettings
    @StateObject private var viewModel: SearchMapViewModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var isSearchAndFollowLinkActive: Bool
    @EnvironmentObject var tabSelection: TabBarSelection
    
    init(locationName: String, locationAddress: CLLocationCoordinate2D, parameterType: MeasurementType, sensorType: SensorType, isSearchAndFollowLinkActive: Binding<Bool>) {
        _viewModel = .init(wrappedValue: .init(passedLocation: locationName,
                                               passedLocationAddress: locationAddress,
                                               measurementType: parameterType,
                                               sensorType: sensorType))
        _isSearchAndFollowLinkActive = .init(projectedValue: isSearchAndFollowLinkActive)
    }
    
    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: .top, content: {
                LoadingView(isShowing: $viewModel.showLoadingIndicator, activityIndicatorText: Strings.SearchMapView.loadingText) {
                    ZStack(alignment: .top) {
                        map
                        VStack(alignment: .leading) {
                            Spacer()
                            if !viewModel.sessionsList.isEmpty {
                                cardsTitle
                                    .padding(.horizontal, 5)
                                cards
                                    .frame(width: reader.size.width, height: reader.size.height / 7, alignment: .leading)
                                    .padding(.horizontal, 5)
                                    .padding(.bottom, 28)
                            } else {
                                ZStack(alignment: .topLeading) {
                                    LinearGradient(gradient: Gradient(colors: [.white.opacity(0.1),
                                                                               .white.opacity(0.5),
                                                                               .white.opacity(0.7),
                                                                               .white.opacity(0.8),
                                                                               .white.opacity(0.9),
                                                                               .white]),
                                                   startPoint: .top,
                                                   endPoint: .bottom).ignoresSafeArea()
                                        .frame(width: reader.size.width, height: reader.size.height / 3.5, alignment: .bottom)
                                    VStack(alignment: .leading) {
                                        cardsTitle
                                            .padding(.bottom, 10)
                                        noSessionsText
                                    }
                                    .padding(.horizontal, 5)
                                    .padding(.top, 60)
                                }
                            }
                        }
                    }
                }
                VStack(alignment: .center, content: {
                    addressTextField
                        .font(Fonts.moderateRegularHeading2)
                    HStack {
                        measurementTypeText
                        Spacer()
                        sensorTypeText
                    }
                    .padding(.bottom, 10)
                    searchAgainButton
                        .foregroundColor(.white)
                        .frame(width: reader.size.width / 2.2, height: 8, alignment: .center)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                        .padding(-3)
                        .shadow(color: Color.shadow, radius: 9, x: 0, y: 1)
                        .disabled(!viewModel.searchAgainButton)
                        .opacity(viewModel.searchAgainButton ? 1.0 : 0.0)
                })
                .padding(.top, 20)
                .padding(.horizontal)
            })
        }
        .onChange(of: viewModel.shouldDismissView, perform: { result in
            result ? self.presentationMode.wrappedValue.dismiss() : nil
        })
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                finishButton
            }
        }
        .sheet(isPresented: $viewModel.isLocationPopupPresented) {
            PlacePicker(service: SearchPickerService(addressName: .init(get: {
                viewModel.passedLocation
            }, set: { new in
                viewModel.enteredNewLocation(name: new)
            }), addressLocation: .init(get: {
                viewModel.passedLocationAddress
            }, set: { new in
                viewModel.enteredNewLocationAdress(new)
            })))
        }
    }
}

// MARK: - Private View Components
private extension SearchMapView {
    var addressTextField: some View {
        createTextfield(placeholder: Strings.SearchView.placeholder,
                        binding: .init(get: {
            viewModel.passedLocation
        }, set: { new in
            viewModel.enteredNewLocation(name: new)
        }))
        .disabled(true)
        .onTapGesture { viewModel.textFieldTapped() }
    }
    
    var measurementTypeText: some View {
        Text(String(format: Strings.SearchMapView.parameterText, arguments: [viewModel.getMeasurementName()]))
            .font(Fonts.muliSemiboldHeading2)
            .lineLimit(1)
            .scaledToFill()
    }
    
    var sensorTypeText: some View {
        Text(String(format: Strings.SearchMapView.sensorText, arguments: [viewModel.getSensorName()]))
            .font(Fonts.muliSemiboldHeading2)
            .lineLimit(1)
            .scaledToFill()
    }
    
    var searchAgainButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                viewModel.redoTapped()
            }
        } label: {
            Text("\(Strings.SearchMapView.redoText) \(Image(systemName: "goforward"))")
                .font(Fonts.muliBoldHeading2)
                .lineLimit(1)
                .scaledToFill()
        }
    }
    
    var map: some View {
        GeometryReader { reader in
            ZStack(alignment: .top) {
                SearchAndFollowMap(startingPoint: $viewModel.passedLocationAddress,
                                   showSearchAgainButton: $viewModel.searchAgainButton,
                                   sessions: $viewModel.sessionsList,
                                   selectedPointerID: $viewModel.cardPointerID)
                .onPositionChange(action: { geoSquare in
                    viewModel.mapPositionsChanged(geoSquare: geoSquare)
                })
                .onMarkerChange(action: { pointer in
                    viewModel.markerSelectionChanged(using: pointer)
                })
                .onStartingLocationChange { geoSquare in
                    viewModel.startingLocationChanged(geoSquare: geoSquare)
                }
                .padding(.top, userSettings.satteliteMap ? 100 : 50)
                .ignoresSafeArea(.all, edges: [.bottom])
                if !userSettings.satteliteMap {
                    LinearGradient(gradient: Gradient(colors: [.white.opacity(0.1),
                                                               .white.opacity(0.5),
                                                               .white.opacity(0.7),
                                                               .white.opacity(0.8),
                                                               .white.opacity(0.9),
                                                               .white]),
                                   startPoint: .bottom,
                                   endPoint: .top)
                    .frame(width: reader.size.width, height: reader.size.height / 4.5, alignment: .top)
                }
            }
        }
    }
    
    var cardsTitle: some View {
        StringCustomizer.customizeString(String(format: Strings.SearchMapView.cardsTitle,
                                                arguments: ["\(viewModel.sessionsList.count)",
                                                            "\(viewModel.sessionsList.count)"]),
                                         using: [Strings.SearchMapView.sessionsText],
                                         color: userSettings.satteliteMap ? .white : .darkBlue,
                                         standardColor: userSettings.satteliteMap ? .white : .darkBlue,
                                         font: Fonts.muliBoldHeading1)

        .foregroundColor(.darkBlue)
    }
    
    var noSessionsText: some View {
        Text(Strings.SearchMapView.noResults)
            .foregroundColor(.darkBlue)
    }
    
    var cards: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(viewModel.sessionsList, id: \.id) { sessionMarker in
                        let session = sessionMarker.session
                        BottomCardView(session: session)
                            .onMarkerChange(action: { pointer in
                                viewModel.markerSelectionChanged(using: pointer)
                            })
                            .background(
                                Group {
                                    Color.white
                                        .cornerRadius(8)
                                        .shadow(color: .sessionCardShadow, radius: 1, x: 0, y: 2)
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(viewModel.strokeColor(with: session.id), lineWidth: 1)
                            ).padding(2)
                    }
                }
                .onChange(of: viewModel.cardPointerID.number , perform: { newValue in
                    withAnimation(.linear) {
                        scrollProxy.scrollTo(viewModel.cardPointerID.number, anchor: .leading)
                    }
                })
            }
        }
    }
    
    var finishButton: some View {
        Button {
            isSearchAndFollowLinkActive = false
            tabSelection.selection = .dashboard
        } label: {
            Text(Strings.SearchMapView.finishText)
                .font(Fonts.muliRegularHeading3.bold())
                .padding(.trailing, 7)
        }
        .overlay(
            Capsule()
                .frame(width: 85, height: 35)
                .foregroundColor(.accentColor)
                .opacity(0.1)
        )
        .padding(.trailing, 10)
    }
}
