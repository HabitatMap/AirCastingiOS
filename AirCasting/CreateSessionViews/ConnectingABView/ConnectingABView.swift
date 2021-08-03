//
//  ConnectingABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import CoreBluetooth
import SwiftUI

struct ConnectingABView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ConnectingABViewModel
    @State var selectedPeripheral: CBPeripheral? = nil
    let baseURL: BaseURLProvider
    @Binding var creatingSessionFlowContinues: Bool
    
    var body: some View {
        VStack(spacing: 50) {
            ProgressView(value: 0.5)
            ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom), content: {
                Image("airbeam")
                    .resizable()
                    .frame(width: 300, height: 400)
                loader
                    .padding()
                    .padding(.vertical)
            })
            
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            .background(
                NavigationLink(
                    destination: ABConnectedView(creatingSessionFlowContinues: $creatingSessionFlowContinues, baseURL: baseURL),
                    isActive: $viewModel.isDeviceConnected,
                    label: {
                        EmptyView()
                    }
                )
            )
        }
        .padding()
        .onChange(of: viewModel.shouldDismiss, perform: { value in
            presentationMode.wrappedValue.dismiss()
        })
        .onAppear(perform: {
            viewModel.connectToAirBeam(peripheral: selectedPeripheral!)
        })
    }
    
    var titleLabel: some View {
        Text("Connecting")
            .font(Font.moderate(size: 25,
                                weight: .bold))
            .foregroundColor(.accentColor)
    }
    
    var messageLabel: some View {
        Text("This should take less than 10 seconds.")
            .font(Font.moderate(size: 18,
                                weight: .regular))
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

#if DEBUG
struct ConnectingABView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectingABView(viewModel: ConnectingABViewModel(airBeamConnectionController: DummyAirBeamConnectionController()), baseURL: DummyURLProvider(), creatingSessionFlowContinues: .constant(true))
    }
 }
#endif
