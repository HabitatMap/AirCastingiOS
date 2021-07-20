//
//  ConnectingABView.swift
//  AirCasting
//
//  Created by Lunar on 04/02/2021.
//

import SwiftUI
import CoreBluetooth

struct ConnectingABView: View {
    
    var bluetoothManager: BluetoothManager
    var selectedPeripheral: CBPeripheral
    let baseURL: BaseURLProvider
    @State private var isDeviceConnected: Bool = false
    
    @Binding var creatingSessionFlowContinues : Bool

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
                    isActive: $isDeviceConnected,
                    label: {
                        EmptyView()
                    })
            )}
        .padding()
        .onAppear(perform: {
            bluetoothManager.centralManager.connect(selectedPeripheral,
                                                    options: nil)
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(rawValue: "DeviceConnected")), perform: { _ in
            /* App is pushing the next view before this view is fully loaded. It resulted with showing next view and going back to this one.
             The async enables app to load this view and then push the next one. */
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                if selectedPeripheral.state == .connected {
                    isDeviceConnected = true
                }
            }
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
//struct ConnectingABView_Previews: PreviewProvider {
//    static var previews: some View {
//        ConnectingABView(bluetoothManager: BluetoothManager(), selectedDevice: CBPeripheral)
//    }
//}
