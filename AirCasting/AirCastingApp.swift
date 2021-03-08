//
//  AirCastingApp.swift
//  AirCasting
//
//  Created by Lunar on 07/01/2021.
//

import SwiftUI
import Firebase

@main
struct AirCastingApp: App {
    @ObservedObject var bluetoothManager = BluetoothManager()
    let persistenceController = PersistenceController.shared
    
    @State var test: Any?
    
    var body: some Scene {
        WindowGroup {
//            Color.red
            MainTabBarView()
                .onAppear {
                    FirebaseApp.configure()
                    
//
//                    test = AuthorizationAPI.createAccount(input: AuthorizationAPI.SignupAPIInput(user: AuthorizationAPI.SignupUserInput(email: "bilbo@gmail.com",
//                                                                                                                                 username: "bilbo123",
//                                                                                                                                 password: "baggins123",
//                                                                                                                                 send_emails: false)))
//                        .sink { (compl) in
//
//                        } receiveValue: { (out) in
//
//                        }
//                    return;
//
//
                    test = AuthorizationAPI
                        .signIn(input: AuthorizationAPI.SigninUserInput(username: "bilbo123",
                                                                        password: "baggins123"))
                        .sink(receiveCompletion: { (compl) in
                            print("Compl.")
                            switch compl {
                            case .failure(let error):
                                print(error.localizedDescription)
                            case .finished: print("Donee")
                            }
                        }, receiveValue: { (out) in
                            print(out)
                        })

                    return;
                    
//.com\",\"authentication_token\":\"f5YX-oHsKVdxozzB3YNf\",\"username\":\"bilbo123\",\"session_stopped_alert\":false}"

                    
                    print("Strating api...")
                    test = CreateSessionApi().createEmptyFixedWifiSession(input: .mock)
                        .sink(receiveCompletion: { (completion) in
                            switch completion {
                            case .failure(let error):
                                print(error.localizedDescription)
                            case .finished:
                                print("OK")
                            }
                            print("End.")
                        }, receiveValue: { (output) in
                            print(output)
                            print("...")
                        })
                    
                }
                .environmentObject(bluetoothManager)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
