//
//  Dashboard.swift
//  AirCasting
//
//  Created by Lunar on 01/02/2021.
//

import SwiftUI

struct Dashboard: View {
    
    let sessions: [Session] = [Session(name: "Podgórze"),
                               Session(name: "Krowodrza Górka"),
                               Session(name: "Mistrzejowice")]
    
    var body: some View {
        NavigationView {
            VStack {
                sectionPicker
                
                ScrollView(.vertical) {
                    LazyVStack(spacing: 20) {
                        ForEach(sessions) { (session) in
                            SessionCell()
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .background(Color.aircastingGray.opacity(0.05))
            }
            .navigationBarTitle("Dashboard")
        }
        .tabItem {
            Image(systemName: "house")
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
}

struct Dashboard_Previews: PreviewProvider {
    static var previews: some View {
        Dashboard()
    }
}
