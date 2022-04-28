//
//  RootAppView.swift
//  AirCasting
//
//  Created by Lunar on 16/03/2021.
//

import SwiftUI
import CoreLocation
import Resolver

struct RootAppView: View {

    @InjectedObject var userAuthenticationSession: UserAuthenticationSession
    @InjectedObject var lifeTimeEventsProvider: LifeTimeEventsProvider
    
    var body: some View {
        ZStack {
            if userAuthenticationSession.isLoggedIn {
                MainAppView()
            } else if !userAuthenticationSession.isLoggedIn && lifeTimeEventsProvider.hasEverPassedOnBoarding {
                NavigationView {
                    CreateAccountView(completion: { self.lifeTimeEventsProvider.hasEverLoggedIn = true }).environmentObject(lifeTimeEventsProvider)
                }
            } else {
                GetStarted(completion: {
                    self.lifeTimeEventsProvider.hasEverPassedOnBoarding = true
                })
            }
        }
        .environment(\.managedObjectContext, Resolver.resolve(PersistenceController.self).viewContext) //TODO: Where is this used??
    }
    
}

struct MainAppView: View {
    @Injected private var persistenceController: PersistenceController
    @InjectedObject private var user: UserState
    
    var body: some View {
        let shouldPresentLoading = Binding<Bool>(get: { user.currentState != .idle } , set: { _ in assertionFailure("Unexpected binding setting") })
        LoadingView(isShowing: shouldPresentLoading, activityIndicatorText: user.currentState == .loggingOut ? Strings.MainTabBarView.loggingOut : Strings.MainTabBarView.deletingAccount) {
            MainTabBarView(sessionContext: CreateSessionContext(),
                           coreDataHook: CoreDataHook(context: persistenceController.viewContext))
        }
    }
}
