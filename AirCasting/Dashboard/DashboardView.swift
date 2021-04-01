//
//  Dashboard.swift
//  AirCasting
//
//  Created by Lunar on 01/02/2021.
//

import SwiftUI

struct DashboardView: View {
    
    @FetchRequest<Session>(sortDescriptors: [NSSortDescriptor(key: "startTime",
                                                              ascending: false)]) var sessions

    var body: some View {
        VStack {
            sectionPicker
            
            if sessions.isEmpty {
                EmptyDashboardView()
            } else {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 20) {
                        ForEach(sessions, id: \.uuid) { (session) in
                            SessionCellView(session: session)
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .background(Color.aircastingGray.opacity(0.05))
            }
        }
        .navigationBarTitle("Dashboard")
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
        DashboardView()
    }
}
