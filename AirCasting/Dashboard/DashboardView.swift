//
//  Dashboard.swift
//  AirCasting
//
//  Created by Lunar on 01/02/2021.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @FetchRequest<Session>(sortDescriptors: [NSSortDescriptor(key: "startTime",
                                                              ascending: false)]) var sessions
    
    @State var isActive : Bool = false
    
    var body: some View {
        NavigationView {
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
                
                bottomNavigation
            }
            .navigationBarTitle("Dashboard")
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
    
    var bottomNavigation: some View {
        ZStack{
            Color(.white)
                .frame(height: 80)
                .offset(x: 0, y: 30)
            HStack {
                Spacer()
                Image(systemName: "house")
                    .foregroundColor(.accentColor)
                Spacer()
                NavigationLink(
                    destination: ChooseSessionTypeView(sessionContext: CreateSessionContext(createSessionService: CreateSessionAPIService(authorisationService: userAuthenticationSession), managedObjectContext: managedObjectContext)),
                    label: {
                        Image(systemName: "plus")
                            .renderingMode(.original)
                            .opacity(0.5)
                    })
                Spacer()
                NavigationLink(
                    destination: SettingsView(),
                    label: {
                        Image(systemName: "gearshape")
                            .renderingMode(.original)
                            .opacity(0.5)
                    })
                Spacer()
            }
            .padding(.top, 30)
        }
        .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.1), radius: 20)
    }
}

#if DEBUG
struct Dashboard_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
#endif
