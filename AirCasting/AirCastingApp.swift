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
    
    let userDefaults = UserDefaults.standard
    @ObservedObject var bluetoothManager = BluetoothManager()
    @State var test: Any?
    
    var body: some Scene {
        WindowGroup {
            MainTabBarView()
                .onAppear {
                    FirebaseApp.configure()
                    
                    test = AuthorizationAPI
                        .signIn(input: AuthorizationAPI.SigninUserInput(username: "bilbo123",
                                                                        password: "baggins123"))
                        .sink(receiveCompletion: { (compl) in
                            print("Compl.")
                            switch compl {
                            case .failure(let error):
                                print(error.localizedDescription)
                            case .finished:
                                print("Donee")
                            }
                        }, receiveValue: { (output) in
                            userDefaults.set(output.authentication_token, forKey: "auth_token")
                            print(output)
                        })
                    
                    return;
                       
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
