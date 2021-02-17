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
    var selecedPeripheral: CBPeripheral
    @State private var isDeviceConnected: Bool = false

    var body: some View {
        VStack(spacing: 50) {
            ProgressView(value: 0.5)
            Image("3-connnect")
            VStack(alignment: .leading, spacing: 15) {
                titleLabel
                messageLabel
            }
            .background(
                NavigationLink(
                    destination: AirbeamConnectedView(),
                    isActive: $isDeviceConnected,
                    label: {
                        EmptyView()
                    }
                )
            )
        }
        .padding()
        .onAppear(perform: {
            bluetoothManager.centralManager.connect(selecedPeripheral,
                                                    options: nil)
        })
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(rawValue: "DeviceConnected")), perform: { _ in
            if selecedPeripheral.state == .connected {
                isDeviceConnected = true
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
}
//struct ConnectingABView_Previews: PreviewProvider {
//    static var previews: some View {
//        ConnectingABView(bluetoothManager: BluetoothManager(), selectedDevice: CBPeripheral)
//    }
//}
