//
//  SelectPeripheralView.swift
//  AirCasting
//
//  Created by Lunar on 02/02/2021.
//

import SwiftUI

struct SelectPeripheralView: View {
    
    var bluetoothManager = BluetoothManager()
    let availableDevices: [String] = ["AirBeam 1",
                                      "AirBeeam 2",
                                      "AirBeam 3"]
    
    
    var body: some View {
        VStack {
            List(availableDevices, id: \.self) { device in
                showDevice(name: device)
            }
            Button("Start scanning") {
                bluetoothManager.startScanning()
            }
        }
    }
    
    var titileLabel: some View {
        Text("Choose the evice you'd like to record with")
    }
    
    func showDevice(name: String) -> some View {
        Text(name)
    }
}

struct SelectPeripheralView_Previews: PreviewProvider {
    static var previews: some View {
        SelectPeripheralView()
    }
}
