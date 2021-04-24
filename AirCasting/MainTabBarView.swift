//
//  ContentView.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI
import CoreData
import Firebase

struct MainTabBarView: View {
    let measurementUpdatingService: MeasurementUpdatingService
    @EnvironmentObject var userAuthenticationSession: UserAuthenticationSession
    @Environment(\.managedObjectContext) var managedObjectContext
    var body: some View {
        DashboardView()
        .onAppear {
            try! measurementUpdatingService.start()
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabBarView(measurementUpdatingService: MeasurementUpdatingServiceMock())
            .environmentObject(UserAuthenticationSession())
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }

    private class MeasurementUpdatingServiceMock: MeasurementUpdatingService {
        func start() throws {}
    }
}
#endif
