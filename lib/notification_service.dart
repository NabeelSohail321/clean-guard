import 'dart:io';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

import 'main.dart';

class NotificationServices {
  // Existing notification properties
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // BuildContext? get _globalContext {
  //   return navigatorKey.currentState?.overlay?.context;
  // }

  // Video call properties
  final Uuid _uuid = Uuid();
  bool _callKitInitialized = false;

  /* ------------------------- */
  /* EXISTING NOTIFICATION METHODS (UNCHANGED) */
  /* ------------------------- */

  Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        criticalAlert: true,
        provisional:
        false, // Changed to false to get full authorization immediately
        sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permission");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("User granted provisional permission");
    } else {
      // AppSettings.openAppSettings(); // Removed auto-open as it can be annoying on every start
      print("User denied permission or has not yet granted it");
    }

    // Set foreground notification options for iOS
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> initLocalNotifications(
      BuildContext context, RemoteMessage message) async {
    var androidInitialization =
    AndroidInitializationSettings("@mipmap/ic_launcher");
    var iosInitialilization = DarwinInitializationSettings();

    var initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialilization,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (payload) {});
  }

  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      print(message.notification!.title);
      if (message.data['type'] == 'video_call') {
        // _handleIncomingCall(context,message);
        initLocalNotifications(context, message);
        showNotification(message);
      } else {
        if (Platform.isAndroid || Platform.isIOS) {
          initLocalNotifications(context, message);
          showNotification(message);
        }
      }
    });

    // Handle when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data['type'] == 'video_call') {
        // _handleIncomingCall(context,message);
        initLocalNotifications(context, message);
        showNotification(message);
      }
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
        Random().nextInt(100000).toString(), "High Importance Notifications",
        importance: Importance.max);

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channel.id, channel.name,
        channelDescription: 'Channel description',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker');

    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<String?> getDeviceToken() async {
    // Check if Firebase is initialized
    if (Firebase.apps.isEmpty) {
      print("Firebase is NOT initialized.");
      return null;
    }

    // Get the default Firebase app
    FirebaseApp app = Firebase.app();

    // Print app details
    print("Firebase App Name: ${app.name}");
    print("Firebase Project ID: ${app.options.projectId}");
    print("Firebase API Key: ${app.options.apiKey}");
    print("Firebase Messaging Sender ID: ${app.options.messagingSenderId}");

    // Get FCM token
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    print("Hello FCM Device Token: $token");

    return token;
  }

  void isTokenRefresh() => messaging.onTokenRefresh.listen((token) {
    print("Token refreshed: $token");
  });

/* ------------------------- */
/* VIDEO CALL METHODS */
/* ------------------------- */
}
