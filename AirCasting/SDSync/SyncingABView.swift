//
//  ConnectingABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import CoreBluetooth
import SwiftUI

struct SyncingABView<VM: SDSyncViewModel>: View {
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: VM
    let baseURL: BaseURLProvider
    @Binding var creatingSessionFlowContinues: Bool
    @State private var showNextScreen: Bool = false
    @State private var presentAlert: Bool = false
    
    
    var body: some View {
        VStack(spacing: 50) {
            ProgressView(value: 0.5)
            ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom), content: {
                Image("airbeam")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                loader
                    .padding()
                    .padding(.vertical)
            })
            
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
        }.background(
            NavigationLink(
                destination: Text("Complete"),
                isActive: $showNextScreen,
                label: {
                    EmptyView()
                }
            )
        )
        .padding()
        .onReceive(viewModel.isSyncCompleted, perform: { isConnected in
            showNextScreen = isConnected
        })
        .onReceive(viewModel.shouldDismiss, perform: { dismiss in
            presentAlert = dismiss
            
        })
        .alert(isPresented: $presentAlert, content: {
            Alert(title: Text(Strings.AirBeamConnector.connectionTimeoutTitle),
                  message: Text(Strings.AirBeamConnector.connectionTimeoutDescription),
                  dismissButton: .default(Text(Strings.AirBeamConnector.connectionTimeoutActionTitle), action: {
                presentationMode.wrappedValue.dismiss()
            }))
        })
        .onAppear(perform: {
            /* App is pushing the next view before this view is fully loaded. It resulted with showing next view and going back to this one.
             The async enables app to load this view and then push the next one. */
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                viewModel.connectToAirBeamAndSync()
            }
        })
    }
    
    var titleLabel: some View {
        Text("Syncing")
            .font(Fonts.boldTitle3)
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text("Keep your AirBeam close to your iPhone. Plug in your AirBeam to speed up the sync.")
            .font(Fonts.regularHeading1)
            .foregroundColor(.aircastingGray)
    }
    
    var loader: some View {
        ZStack {
            Color.accentColor
                .frame(width: 70, height: 70)
                .clipShape(Circle())
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                .scaleEffect(2)
        }
    }
}
