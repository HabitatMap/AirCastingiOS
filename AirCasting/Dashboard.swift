//
//  ContentView.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI

struct Dashboard: View {
    
    var body: some View {
        TabView {
            dashboardTab
            createSessionTab
            settingsTab
        }
    }
    
    private var dashboardTab: some View {
        NavigationView {
            VStack {
                sectionPicker
                emptyState
            }
        }
        .tabItem {
            Image(systemName: "house")
        }
    }
    private var createSessionTab: some View {
        Color.aircastingGray
            .tabItem {
                Image(systemName: "plus")
            }
    }
    private var settingsTab: some View {
        Color.aircastingGray
            .tabItem {
                Image(systemName: "gearshape")
            }
    }
    
    var sectionPicker: some View {
        Picker(selection: .constant(1), label: Text("Picker"), content: {
            Text("Following").tag(1)
            Text("Active").tag(2)
            Text("Dormant").tag(3)
            Text("Fixed").tag(4)
        })
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    private var emptyState: some View {
        VStack(spacing: 45) {
            Spacer()
            VStack(spacing: 14) {
                
                Text("Ready to get started?")
                    .font(Font.moderate(size: 24, weight: .bold))
                    .foregroundColor(Color.darkBlue)
                
                Text("Explore & follow existing AirCasting sessions or use your own device to record a new session and monitor your health & environment.")
                    .font(Font.muli(size: 16))
                    .foregroundColor(Color.aircastingGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(9.0)
                    .padding(.horizontal, 45)
            }
            VStack(spacing: 20) {
                Button(action: {}, label: {
                    Text("Record new session")
                        .bold()
                })
                .buttonStyle(AirButtonStyle())
                
                Button(action: {}, label: {
                    Text("Explore existing sessions")
                        .foregroundColor(.accentColor)
                })
            }
            Spacer()
        }
        .padding()
        .navigationBarTitle("Dashboard")
        .background(Color(red: 251/255, green: 253/255, blue: 255/255))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Dashboard()
    }
}
