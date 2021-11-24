import SwiftUI
import Firebase
import FirebaseMessaging

@objc
class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    private let notificationsRouter = DefaultRemoteNotificationRouter.shared
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        application.registerForRemoteNotifications()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Log.info("Got APNS token: \(deviceToken)")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Log.error("Couldnt register for APNS: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Log.info("Got APNS message: \(userInfo)")
        notificationsRouter.handleSystemNotification(userInfo: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Log.info("fcm token received: \(fcmToken ?? "none")")
        Messaging.messaging().subscribe(toTopic: "feature_flags")
    }
}
