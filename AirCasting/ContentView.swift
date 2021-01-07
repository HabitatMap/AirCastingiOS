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
            VStack(spacing: 20) {
                Button(action: {}, label: {
                    Text("Record new session")
                        .bold()
                        .foregroundColor(Color.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 40)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                        .padding(-3)
                        .shadow(color: Color(white: 150/255, opacity: 0.5), radius: 9, x: 0, y: 1)
                })
                Button(action: {}, label: {
                    Text("Explore existing sessions")
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
