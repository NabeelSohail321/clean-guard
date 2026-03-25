import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, MessagingDelegate {

 override func application(
   _ application: UIApplication,
   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
 ) -> Bool {

   // Initialize Firebase (only if not already initialized)
   if FirebaseApp.app() == nil {
     FirebaseApp.configure()
     print("Firebase initialized")
   }

   // Set Messaging delegate to receive FCM token updates
   Messaging.messaging().delegate = self

   // Register for remote notifications (APNs)
   application.registerForRemoteNotifications()

   // Set UNUserNotificationCenter delegate to handle foreground notifications
   UNUserNotificationCenter.current().delegate = self

   return super.application(application, didFinishLaunchingWithOptions: launchOptions)
 }

 func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
   GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
 }

 // MARK: - APNs token handling
 override func application(
   _ application: UIApplication,
   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
 ) {
   // Convert APNs device token to hex string
   let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
   let apnsToken = tokenParts.joined()
   print("APNs Device Token: \(apnsToken)")

   // Pass the APNs token to Firebase
   Messaging.messaging().apnsToken = deviceToken
   super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
 }

 // MARK: - FCM token refresh
 func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
   // Print FCM token; the Dart side can also call getToken()
   print("FCM Registration token updated: \(String(describing: fcmToken))")
 }

 // MARK: - Foreground notification handling
 override func userNotificationCenter(
   _ center: UNUserNotificationCenter,
   willPresent notification: UNNotification,
   withCompletionHandler completionHandler:
   @escaping (UNNotificationPresentationOptions) -> Void
 ) {
   // Let the Dart NotificationServices handle showing notifications
   completionHandler([.alert, .badge, .sound])
 }
}