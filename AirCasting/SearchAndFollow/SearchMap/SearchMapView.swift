// Created by Lunar on 16/02/2022.
//

import CoreLocation
import Foundation
import SwiftUI
import AirCastingStyling

struct SearchMapView: View {
    @StateObject private var viewModel: SearchMapViewModel
    @Environment(\.presentationMode) var presentationMode
    @State var showCompleteScreen = false
    
    init(locationName: String, locationAddress: CLLocationCoordinate2D, parameterType: MapDownloaderMeasurementType, sensorType: MapDownloaderSensorType) {
        _viewModel = .init(wrappedValue: .init(passedLocation: locationName,
                                               passedLocationAddress: locationAddress,
                                               measurementType: parameterType,
                                               sensorType: sensorType))
    }
    
    var body: some View {
        ZStack(alignment: .top, content: {
            LoadingView(isShowing: $viewModel.showLoadingIndicator, activityIndicatorText: Strings.SearchMapView.loadingText) {
                map
            }
            VStack(alignment: .center, content: {
                addressTextField
                HStack {
                    measurementTypeText
                    Spacer()
                    sensorTypeText
                }
                searchAgainButton
                // This is temporary untill we implement clickable cards
                Spacer()
                Button(action: { showCompleteScreen = true }, label: { Text("Complete screen") })
            })
                .padding(.top, 50)
                .padding(.horizontal)
        })
            .onChange(of: viewModel.shouldDismissView, perform: { result in
                result ? self.presentationMode.wrappedValue.dismiss() : nil
            })
            .alert(item: $viewModel.alert, content: { $0.makeAlert() })
            .sheet(isPresented: $showCompleteScreen, content: { CompleteScreen(session: SearchSessionResult.mock) })
    }
}

// MARK: - Private View Components
private extension SearchMapView {
    var addressTextField: some View {
        createTextfield(placeholder: "", binding: .constant(viewModel.passedLocation))
            .disabled(true)
    }
    
    var measurementTypeText: some View {
        Text(String(format: Strings.SearchMapView.parameterText, arguments: [viewModel.measurementType.name]))
            .font(Fonts.semiboldHeading2)
            .lineLimit(1)
            .scaledToFit()
    }
    
    var sensorTypeText: some View {
        Text(String(format: Strings.SearchMapView.sensorText, arguments: [viewModel.sensorType.name]))
            .font(Fonts.semiboldHeading2)
            .lineLimit(1)
            .scaledToFit()
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
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }
            .foregroundColor(.white)
            .background(Color.accentColor)
            .cornerRadius(5)
            .padding(-3)
            .shadow(color: Color.shadow, radius: 9, x: 0, y: 1)
            .disabled(!viewModel.searchAgainButton)
            .opacity(viewModel.searchAgainButton ? 1.0 : 0.0)
    }
    
    var map: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                SearchAndFollowMap(startingPoint: viewModel.passedLocationAddress,
                                   showRedoButton: $viewModel.searchAgainButton,
                                   sessions: $viewModel.sessionsList).onPositionChange(action: { geoSquare in
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
                    .frame(width: geometry.size.width, height: geometry.size.height / 4.5, alignment: .top)
                
            }
        }
    }
}
