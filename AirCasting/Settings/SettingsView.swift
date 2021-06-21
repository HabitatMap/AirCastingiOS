//
//  LogoutView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import Foundation
import AirCastingStyling

struct SettingsView: View {
    let logoutController: LogoutController
    @State private var isToggle : Bool = false
    @State private var showModal = false
    var body: some View {
        NavigationView {
            List {
                Section() {
                    NavigationLink(destination: MyAccountViewSingOut()) {
                        Text("My Account")
                    }
                }
                
                Section() {
                    VStack(alignment: .leading) {
                        HStack(spacing: 5) {
                            Text("Contribute to CrowdMap")
                            Toggle(isOn: $isToggle){
                                Text("Switch")
                                    .font(.title)
                                    .foregroundColor(Color.white)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        }
                        Spacer()
                        Text("Data contributed to the CrowdMap is publicly available at aircasting.org")
                            .fontWeight(.light)
                    }
                    
                    Button(action: {
                        showModal.toggle()
                    }) {
                        Group {
                            HStack {
                                Text("Backend settings")
                                    .accentColor(.black)
                                Spacer()
                                Image(systemName: "control")
                                    .accentColor(.gray).opacity(0.6)
                            }
                        }
                    }.sheet(isPresented: $showModal, content: {
                        BackendSettingsModalView()
                    })
                }
                
                Section() {
                    NavigationLink(destination: Text("Help")) {
                        Text("Help")
                    }
                    NavigationLink(destination: Text("Hardware developers")) {
                        Text("Hardware developers")
                    }
                    NavigationLink(destination: Text("About AirCasting")) {
                        Text("About AirCasting")
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Settings")
        }
    }
    
    
   private struct BackendSettingsModalView: View {
        @Environment(\.presentationMode) var presentationMode
        @State var url: String = ""
        @State var port: String = ""
        
        var body: some View {
            VStack(alignment: .leading) {
                Text("Backend settings")
                    .font(.title2)
                Spacer()
                createTextfield(placeholder: "Enter url", binding: $url)
                createTextfield(placeholder: "Enter port", binding: $port)
                Spacer()
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }.buttonStyle(BlueButtonStyle())
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }.buttonStyle(BlueTextButtonStyle())
            }
            .padding()
        }
    }
}

#if DEBUG
struct LogoutView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(logoutController: FakeLogoutController())
    }
}
#endif
