//
//  ConnectingABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import CoreBluetooth
import SwiftUI
import AirCastingStyling

struct ConnectingABView<VM: AirbeamConnectionViewModel>: View {
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: VM
    let baseURL: BaseURLProvider
    let locationHandler: LocationHandler
    @Binding var creatingSessionFlowContinues: Bool
    @State private var showNextScreen: Bool = false
    @State private var presentAlert: Bool = false
    
    
    var body: some View {
        VStack() {
            ProgressView(value: 0.5)
                .padding(.bottom, 50)
            ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom), content: {
                Image("airbeam")
                    .resizable()
                    .scaledToFit()
                    .padding(.bottom, 15)
                loader
                    .padding()
                    .padding(.vertical)
            }).frame(width: UIScreen.main.bounds.width - 40, height:  UIScreen.main.bounds.height / 2, alignment: .center)
            VStack(alignment: .leading, spacing: 15) {
               titleLabel
               messageLabel
           }
            Spacer()
        }
        .background(
            NavigationLink(
                destination: ABConnectedView(creatingSessionFlowContinues: $creatingSessionFlowContinues, baseURL: baseURL, locationHandler: locationHandler),
                isActive: $showNextScreen,
                label: {
                    EmptyView()
                }
            )
        )
        .padding()
        .onReceive(viewModel.isDeviceConnected, perform: { isConnected in
            showNextScreen = isConnected
        })
        .onReceive(viewModel.shouldDismiss, perform: { dismiss in
            presentAlert = dismiss
            
        })
        .alert(isPresented: $presentAlert, content: {
            Alert(title: Text(Strings.AirBeamConnector.connectionTimeoutTitle),
                  message: Text(Strings.AirBeamConnector.connectionTimeoutDescription),
                  dismissButton: .default(Text(Strings.Commons.gotIt), action: {
                presentationMode.wrappedValue.dismiss()
            }))
        })
        .onAppear(perform: {
            /* App is pushing the next view before this view is fully loaded. It resulted with showing next view and going back to this one.
             The async enables app to load this view and then push the next one. */
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                viewModel.connectToAirBeam()
            }
        })
    }
    
    var titleLabel: some View {
        Text(Strings.ConnectingABView.title)
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text(Strings.ConnectingABView.message)
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
    }
    
    var loader: some View {
        ZStack {
            Color.accentColor
                .frame(width: 90, height: 90)
                .clipShape(Circle())
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                .scaleEffect(2)
        }
    }
}
