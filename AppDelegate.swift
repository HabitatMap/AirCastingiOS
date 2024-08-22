import SwiftUI
import Firebase
import FirebaseMessaging
import Resolver

@objc
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    var window: UIWindow?

     func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
         
         let sceneConfig : UISceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
         sceneConfig.delegateClass = SceneDelegate.self
         return sceneConfig
         
     }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        if ProcessInfo.processInfo.environment["boot_type"] == "clean" {
            Log.info("Running in clean boot mode, erasing all data and logging out before the app launches")
            performCleanBoot()
        }
        
        Messaging.messaging().delegate = self
        application.registerForRemoteNotifications()
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        if let visabilityValue = notification.request.content.userInfo[NotificationInfoKeys.visability.rawValue] as? String,
           let visability = NotificationVisability(rawValue: visabilityValue) {
            switch visability {
            case .prominent:
                completionHandler([.banner, .list, .sound])
            case .visible:
                completionHandler([.banner, .list])
            case .unnoticed:
                completionHandler([.list])
            }
        }
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
