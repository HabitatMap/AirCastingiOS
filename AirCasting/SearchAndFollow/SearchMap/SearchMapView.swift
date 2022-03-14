// Created by Lunar on 16/02/2022.
//

import CoreLocation
import Foundation
import SwiftUI
import AirCastingStyling

struct SearchMapView: View {
    @StateObject var viewModel: SearchMapViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(locationName: String, locationAddress: CLLocationCoordinate2D, parametr: String) {
        _viewModel = .init(wrappedValue: .init(passedLocation: locationName, passedLocationAddress: locationAddress, passedParameter: parametr))
    }
    
    var body: some View {
            ZStack(alignment: .top, content: {
                LoadingView(isShowing: $viewModel.showLoadingIndicator, activityIndicatorText: Strings.SearchMapView.loadingText) {
                    ZStack(alignment: .top) {
                        map
                        VStack {
                            Spacer()
                            cardsTitle
                            cards
                        }
                    }
                }
                VStack(content: {
                    textField
                    parametersText
                    redoneButton
                })
                    .padding(.top, 50)
                    .padding(.horizontal)
            })
        .onChange(of: viewModel.shouldDismissView, perform: { _ in
            viewModel.shouldDismissView ? self.presentationMode.wrappedValue.dismiss() : nil
        })
        .alert(item: $viewModel.alert, content: { $0.makeAlert() })
    }
}

// MARK: - Private View Components
private extension SearchMapView {
    var textField: some View {
        createTextfield(placeholder: "", binding: .constant(viewModel.passedLocation))
            .disabled(true)
    }
    
    var parametersText: some View {
        Text(String(format: Strings.SearchMapView.parameterText, arguments: [viewModel.passedParameter]))
            .font(.muli(size: 16, weight: .semibold))
    }
    
    var redoneButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                viewModel.redoTapped()
            }
        } label: {
            Text("\(Strings.SearchMapView.redoText) \(Image(systemName: "goforward"))")
                .font(Fonts.boldHeading3)
                .lineLimit(1)
                .scaledToFill()
                .multilineTextAlignment(.leading)
        }
        .foregroundColor(.white)
        .frame(width: UIScreen.main.bounds.width / 2.2, height: 8, alignment: .center)
        .padding(.vertical, 12)
        .background(Color.accentColor)
        .cornerRadius(5)
        .padding(-3)
        .shadow(color: Color.shadow, radius: 9, x: 0, y: 1)
        .disabled(!viewModel.showRedoButton)
        .opacity(viewModel.showRedoButton ? 1.0 : 0.0)
    }
    
    var map: some View {
        ZStack(alignment: .top) {
            SearchAndFollowMap(startingPoint: viewModel.passedLocationAddress,
                      showRedoButton: $viewModel.showRedoButton,
                               sessions: $viewModel.sessionsList,
                               pointerID: $viewModel.cardPointerID).onPositionChange(action: { geoSquare in
                viewModel.mapPositionsChanged(geoSquare: geoSquare)
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
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 4.5, alignment: .top)
        }
    }
    
    var cardsTitle: some View {
        HStack(alignment: .bottom) {
            StringCustomizer.customizeString(String(format: Strings.SearchMapView.cardsTitle, arguments: ["\(viewModel.sessionsList.count)", "\(2500)"]),
                                             using: [Strings.SearchMapView.sessionsText], color: .darkBlue, standardColor: .darkBlue, font: Fonts.boldHeading2)
        }.foregroundColor(.darkBlue)
    }
    
    var cards: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(viewModel.sessionsList, id: \.id) { session in
                        BottomCardView(id: session.id, cardPointer: $viewModel.cardPointerID, title: session.title, startTime: session.startTime)
                            .id(session.id)
                            .border((viewModel.cardPointerID == session.id ? .green : .clear), width: 1)
                            
                    }
                }
                
                .onReceive(viewModel.$cardPointerID) { v in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                    withAnimation(.linear) {
                        scrollProxy.scrollTo(Int(viewModel.cardPointerID), anchor: .leading)
                    }
                }
            }
            }
        }
        .padding(.horizontal, 5)
        .frame(height: UIScreen.main.bounds.height / 9, alignment: .leading)
    }
}
