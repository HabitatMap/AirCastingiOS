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

    @InjectedObject private var userAuthenticationSession: UserAuthenticationSession
    @InjectedObject private var lifeTimeEventsProvider: LifeTimeEventsProvider
    @InjectedObject private var userState: UserState
    @StateObject private var signInPersistanceObserved = SignInPersistance.shared
    
    var body: some View {
        ZStack {
            if userAuthenticationSession.isLoggedIn && userState.currentState != .loggingOut {
                MainAppView()
                    .onAppear {
                        signInPersistanceObserved.clearSavedStatesWithCredentials()
                    }
            } else if !lifeTimeEventsProvider.hasEverPassedOnBoarding {
                GetStarted(completion: {
                    self.lifeTimeEventsProvider.hasEverPassedOnBoarding = true
                })
            } else {
                NavigationView {
                    if signInPersistanceObserved.credentialsScreen == .signIn {
                        withAnimation(.easeIn(duration: 5.0)) {
                        SignInView(completion: { self.lifeTimeEventsProvider.hasEverLoggedIn = true }).environmentObject(lifeTimeEventsProvider)
                        }
                    } else {
                        CreateAccountView(completion: { self.lifeTimeEventsProvider.hasEverLoggedIn = true }).environmentObject(lifeTimeEventsProvider)
                    }
                }
            }
        }
        .environment(\.managedObjectContext, Resolver.resolve(PersistenceController.self).viewContext) //TODO: Where is this used??
        .onAppWentToBackground {
            signInPersistanceObserved.clearSavedStatesWithCredentials()
        }
    }
    
}

struct MainAppView: View {
    @Injected private var persistenceController: PersistenceController
    @InjectedObject private var user: UserState
    
    var body: some View {
        let shouldPresentLoading = Binding<Bool>(get: { user.currentState == .deletingAccount } , set: { _ in assertionFailure("Unexpected binding setting") })
        LoadingView(isShowing: shouldPresentLoading, activityIndicatorText: Strings.MainTabBarView.deletingAccount) {
            MainTabBarView(sessionContext: CreateSessionContext(),
                           coreDataHook: CoreDataHook(context: persistenceController.viewContext))
        }
    }
}
