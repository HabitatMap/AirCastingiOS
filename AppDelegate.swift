import SwiftUI
import Firebase
import FirebaseMessaging
import Resolver

@objc
class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if ProcessInfo.processInfo.environment["clean_boot"] == "YES" {
            Log.info("Running in clean boot mode, erasing all data and logging out before the app launches")
            performCleanBoot()
        }
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        // NOTE: We don't ask user for the remote notifications permissions since we're only using APNS for
        // the firebase config change notifications (silent push notifications - no permission is needed for
        // this kind). If you want to add non-silet notifications, uncomment:
        //
        // let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        // UNUserNotificationCenter.current().requestAuthorization(
        //     options: authOptions,
        //     completionHandler: { _, _ in }
        // )
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Log.info("Got APNS token: \(tokenString)")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Log.error("Couldnt register for APNS: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Log.info("Got APNS message: \(userInfo)")
        let handler = Resolver.resolve(RemoteNotificationsHandler.self)
        handler.handleSystemNotification(userInfo: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Log.info("fcm token received: \(fcmToken ?? "none")")
        Messaging.messaging().subscribe(toTopic: "feature_flags")
    }
    
    private func performCleanBoot() {
        let group = DispatchGroup()
        group.enter()
        Resolver.resolve(DataEraser.self).eraseAllData(completion: { _ in
            group.leave()
        })
        group.wait()
        do {
            try Resolver.resolve(Deauthorizable.self).deauthorize()
        } catch {
            Log.warning("Couldn't deauthorize user: \(error.localizedDescription)")
        }
    }
}
