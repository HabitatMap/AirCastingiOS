// Created by Lunar on 16/02/2022.
//

import CoreLocation
import Foundation
import SwiftUI
import AirCastingStyling

struct SearchMapView: View {
    @StateObject private var viewModel: SearchMapViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(locationName: String, locationAddress: CLLocationCoordinate2D, measurementType: String) {
        _viewModel = .init(wrappedValue: .init(passedLocation: locationName, passedLocationAddress: locationAddress, measurementType: measurementType))
    }
    
    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: .top, content: {
                LoadingView(isShowing: $viewModel.showLoadingIndicator, activityIndicatorText: Strings.SearchMapView.loadingText) {
                    ZStack(alignment: .top) {
                        map
                        VStack(alignment: .leading) {
                            Spacer()
                            cardsTitle
                            cards
                                .frame(width: reader.size.width, height: reader.size.height / 7, alignment: .leading)
                        }
                        .padding(.horizontal, 5)
                        .padding(.bottom, 5)
                    }
                }
                VStack(alignment: .center, content: {
                    addressTextField
                    measurementTypeText
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
                    .padding(.top, 50)
                    .padding(.horizontal)
            })
        }
            .onChange(of: viewModel.shouldDismissView, perform: { result in
                result ? self.presentationMode.wrappedValue.dismiss() : nil
            })
            .alert(item: $viewModel.alert, content: { $0.makeAlert() })
    }
}

// MARK: - Private View Components
private extension SearchMapView {
    var addressTextField: some View {
        createTextfield(placeholder: "", binding: .constant(viewModel.passedLocation))
            .disabled(true)
    }
    
    var measurementTypeText: some View {
        Text(String(format: Strings.SearchMapView.parameterText, arguments: [viewModel.measurementType]))
            .font(.muli(size: 16, weight: .semibold))
    }
    
    var searchAgainButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                viewModel.redoTapped()
            }
        } label: {
            Text("\(Strings.SearchMapView.redoText) \(Image(systemName: "goforward"))")
                .font(Fonts.boldHeading3)
                .lineLimit(1)
                .scaledToFill()
        }
    }
    
    var map: some View {
        GeometryReader { reader in
            ZStack(alignment: .top) {
                SearchAndFollowMap(startingPoint: viewModel.passedLocationAddress,
                                   showSearchAgainButton: $viewModel.searchAgainButton,
                                   sessions: $viewModel.sessionsList,
                                   selectedPointerID: $viewModel.cardPointerID)
                .onPositionChange(action: { geoSquare in
                    viewModel.mapPositionsChanged(geoSquare: geoSquare)
                })
                .onMarkerChange(action: { pointer in
                    viewModel.markerSelectionChanged(using: pointer)
                })
                                   .padding(.top, 50)
                                   .ignoresSafeArea(.all, edges: [.bottom])
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
    
    var cardsTitle: some View {
        StringCustomizer.customizeString(String(format: Strings.SearchMapView.cardsTitle,
                                                arguments: ["\(viewModel.sessionsList.count)",
                                                            "\(viewModel.sessionsList.count)"]),
                                         using: [Strings.SearchMapView.sessionsText],
                                         color: .darkBlue,
                                         standardColor: .darkBlue,
                                         font: Fonts.boldHeading2)
        .foregroundColor(.darkBlue)
    }
    
    var cards: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(viewModel.sessionsList, id: \.id) { session in
                        BottomCardView(id: session.id,
                                       uuid: session.uuid,
                                       title: session.title,
                                       startTime: session.startTime,
                                       endTime: session.endTime,
                                       latitude: session.location.latitude,
                                       longitude: session.location.longitude)
                        .onMarkerChange(action: { pointer in
                            viewModel.markerSelectionChanged(using: pointer)
                        })
                        .border((viewModel.cardPointerID.number == session.id ? Color.accentColor : .clear), width: 1)
                        
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
}
