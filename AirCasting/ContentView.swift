//
//  ContentView.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        TabView {
            NavigationView {
                VStack {
                    Picker(selection: /*@START_MENU_TOKEN@*/.constant(1)/*@END_MENU_TOKEN@*/, label: /*@START_MENU_TOKEN@*/Text("Picker")/*@END_MENU_TOKEN@*/, content: {
                        Text("Following").tag(1)
                        Text("Active").tag(2)
                        Text("Dormant").tag(3)
                        Text("Fixed").tag(4)
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    emptyState
                }
            }
            .tabItem { Text("+") }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 40) {
            Spacer()
            VStack(spacing: 20) {
                Text("Ready to get started?")
                    .bold()
                Text("Explore & follow existing AirCasting sessions or use your own device to record a new session and monitor your health & environment.")
                    .multilineTextAlignment(.center)
                    .lineSpacing(/*@START_MENU_TOKEN@*/10.0/*@END_MENU_TOKEN@*/)
            }
            VStack {
                Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                    Text("Record new session")
                    
                })
            }
            Spacer()
        }
        .padding()
        .navigationBarTitle("Dashboard")
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
