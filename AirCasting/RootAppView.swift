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
    
    @State private var sessionStoppableFactory: SessionStoppableFactoryDefault?

    @InjectedObject var userAuthenticationSession: UserAuthenticationSession
    @InjectedObject var lifeTimeEventsProvider: LifeTimeEventsProvider
    @Injected private var averagingService: AveragingService
    
    var body: some View {
        ZStack {
            if userAuthenticationSession.isLoggedIn,
               let sessionStoppableFactory = sessionStoppableFactory {
                MainAppView(sessionStoppableFactory: sessionStoppableFactory)
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
        .onAppear {
            sessionStoppableFactory = SessionStoppableFactoryDefault()
        }
    }
    
}

struct MainAppView: View {
    
    let sessionStoppableFactory: SessionStoppableFactoryDefault
    @Injected private var persistenceController: PersistenceController
    @InjectedObject private var user: UserState
    
    var body: some View {
        LoadingView(isShowing: $user.isLoggingOut, activityIndicatorText: Strings.MainTabBarView.loggingOut) {
            MainTabBarView(sessionStoppableFactory: sessionStoppableFactory,
                           sessionContext: CreateSessionContext(),
                           coreDataHook: CoreDataHook(context: persistenceController.viewContext))
        }
    }
}
