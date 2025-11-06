// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../config.dart';
//
// class CustomNotificationController extends GetxController {
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//   AndroidNotificationChannel? messageChannel;
//   AndroidNotificationChannel? callChannel;
//   FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
//
//   @override
//   void onInit() {
//     super.onInit();
//     initNotification();
//   }
//
//   // Initialize notifications
//   Future<void> initNotification() async {
//     log('initNotification');
//
//     // Set foreground notification options
//     await FirebaseMessaging.instance
//         .setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//
//     // Request permissions
//     if (Platform.isIOS) {
//       final result = await firebaseMessaging.requestPermission(
//         alert: true,
//         badge: true,
//         provisional: true,
//         sound: true,
//       );
//       final iosResult = await _flutterLocalNotificationsPlugin
//           .resolvePlatformSpecificImplementation<
//               IOSFlutterLocalNotificationsPlugin>()
//           ?.requestPermissions(
//             alert: true,
//             badge: true,
//             sound: true,
//           );
//       log(result.authorizationStatus == AuthorizationStatus.authorized &&
//               iosResult == true
//           ? 'FCM: iOS User granted permission'
//           : 'FCM: iOS User declined permission');
//     } else if (Platform.isAndroid) {
//       final result = await firebaseMessaging.requestPermission(
//         alert: true,
//         badge: true,
//         provisional: true,
//         sound: true,
//       );
//       log('Permission result: ${result.authorizationStatus}');
//     }
//
//     // Create notification channels
//     await _createNotificationChannels();
//
//     // Initialize local notifications
//     await _initLocalNotification();
//
//     // Handle terminated app state
//     FirebaseMessaging.instance
//         .getInitialMessage()
//         .then((RemoteMessage? message) {
//       if (message != null) {
//         log('Terminated state message: ${message.data}');
//         handleMessage(message);
//       }
//     });
//
//     // Setup listeners
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       log('Foreground message received: ${message.data}');
//       handleMessage(message);
//     });
//
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       log('Background message tapped: ${message.data}');
//       handleMessage(message);
//     });
//   }
//
//   /// Create Android notification channels
//   Future<void> _createNotificationChannels() async {
//     messageChannel = const AndroidNotificationChannel(
//       'high_importance_channel',
//       'High Importance Notifications',
//       description: 'This channel is used for message notifications.',
//       importance: Importance.high,
//       playSound: true,
//       sound: RawResourceAndroidNotificationSound('message'),
//       enableLights: true,
//       enableVibration: true,
//       showBadge: true,
//     );
//
//     callChannel = const AndroidNotificationChannel(
//       'call_channel',
//       'Call Notifications',
//       description: 'This channel is used for call notifications.',
//       importance: Importance.max, // Use max for calls
//       playSound: true,
//       sound: RawResourceAndroidNotificationSound('callsound'),
//       enableVibration: true,
//       showBadge: true,
//     );
//
//     final androidPlugin =
//         _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>();
//     await androidPlugin?.deleteNotificationChannel('high_importance_channel');
//     await androidPlugin?.createNotificationChannel(messageChannel!);
//     await androidPlugin?.createNotificationChannel(callChannel!);
//     log('Created notification channels: message=${messageChannel!.id}, call=${callChannel!.id}');
//   }
//
//   /// Initialize local notifications
//   Future<void> _initLocalNotification() async {
//     const androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosSettings = DarwinInitializationSettings();
//     const initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await _flutterLocalNotificationsPlugin.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         log('Notification clicked: ${response.payload}');
//         handleNotificationTap(response.payload);
//       },
//       onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
//     );
//   }
//
//   /// Handle incoming messages
//   void handleMessage(RemoteMessage message) async {
//     final notificationData = message.data;
//     final title = message.notification?.title ??
//         notificationData['name'] ??
//         'New Notification';
//     final body = message.notification?.body ??
//         notificationData['body'] ??
//         'You have a new message';
//     final isCall = notificationData['title'] == 'Incoming Video Call...' ||
//         notificationData['title'] == 'Incoming Audio Call...';
//
//     log('notificationData: $notificationData, isCall: $isCall');
//
//     // Suppress call notifications in background
//     if (isCall &&
//         WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
//       log('Suppressing call notification in background: $title');
//       return;
//     }
//
//     // Clear notifications for call end
//     if (notificationData['title'] == 'Call Ended' ||
//         notificationData['title'] == 'Incoming Call ended') {
//       await _flutterLocalNotificationsPlugin.cancelAll();
//       log('Cleared notifications for Call Ended');
//       return;
//     }
//
//     // Handle navigation for non-call notifications
//     if (!isCall &&
//         notificationData['title'] != 'Missed Call' &&
//         notificationData['title'] != 'You have new message(s)' &&
//         notificationData['title'] != 'Group Message') {
//       if (notificationData['isGroup'] == 'true') {
//         if (notificationData['groupId'] != null) {
//           final groupDoc = await FirebaseFirestore.instance
//               .collection(collectionName.groups)
//               .doc(notificationData['groupId'])
//               .get();
//           Get.toNamed(routeName.groupChatMessage, arguments: groupDoc.data());
//         } else {
//           log('Missing groupId in group notification data');
//         }
//       } else {
//         if (notificationData['chatId'] != null &&
//             notificationData['userContact'] != null) {
//           final data = {
//             'chatId': notificationData['chatId'],
//             'data': notificationData['userContact'],
//             'messageId': notificationData['messageId'],
//           };
//           Get.toNamed(routeName.chatLayout, arguments: data);
//         } else {
//           log('Missing fields in notification data: chatId=${notificationData['chatId']}, userContact=${notificationData['userContact']}');
//         }
//       }
//     }
//
//     await showNotification(message);
//   }
//
//   /// Display notification
//   Future<void> showNotification(RemoteMessage message) async {
//     if (messageChannel == null || callChannel == null) {
//       log('Channels not initialized, reinitializing...');
//       await _createNotificationChannels();
//       if (messageChannel == null || callChannel == null) {
//         log('Error: Failed to initialize channels');
//         return;
//       }
//     }
//
//     final notification = message.notification;
//     final notificationData = message.data;
//     final title =
//         notification?.title ?? notificationData['name'] ?? 'New Notification';
//     final body = notification?.body ??
//         notificationData['body'] ??
//         'You have a new message';
//     final isCall = notificationData['title'] == 'Incoming Video Call...' ||
//         notificationData['title'] == 'Incoming Audio Call...';
//
//     final channel = isCall ? callChannel! : messageChannel!;
//     final soundName = isCall ? 'callsound' : 'message';
//
//     log('Showing notification: title=$title, body=$body, isCall=$isCall, sound=$soundName, channel=${channel.id}');
//
//     if (notification != null) {
//       final androidDetails = AndroidNotificationDetails(
//         channel.id,
//         channel.name,
//         channelDescription: channel.description,
//         icon: '@mipmap/ic_launcher',
//         importance: Importance.max,
//         priority: Priority.high,
//         playSound: true,
//         sound: RawResourceAndroidNotificationSound(soundName),
//         fullScreenIntent: isCall,
//       );
//
//       final iosDetails = DarwinNotificationDetails(
//         sound: soundName,
//         presentSound: true,
//         presentAlert: true,
//         presentBadge: true,
//       );
//
//       final notificationDetails = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );
//
//       await _flutterLocalNotificationsPlugin.show(
//         notification.hashCode,
//         title,
//         body,
//         notificationDetails,
//         payload: jsonEncode(notificationData),
//       );
//       log('Notification shown successfully');
//     }
//   }
//
//   /// Mark messages as seen in Firestore
//   Future<void> markMessagesAsSeen(
//       String chatId, String? messageId, String currentUserId) async {
//     try {
//       if (messageId != null) {
//         await FirebaseFirestore.instance
//             .collection('chats')
//             .doc(chatId)
//             .collection('messages')
//             .doc(messageId)
//             .update({'isSeen': true});
//         log('Marked message $messageId as seen in chat $chatId');
//       } else {
//         final unreadMessages = await FirebaseFirestore.instance
//             .collection('chats')
//             .doc(chatId)
//             .collection('messages')
//             .where('receiverId', isEqualTo: currentUserId)
//             .where('isSeen', isEqualTo: false)
//             .get();
//
//         for (var doc in unreadMessages.docs) {
//           await doc.reference.update({'isSeen': true});
//         }
//         log('Marked ${unreadMessages.docs.length} messages as seen in chat $chatId');
//       }
//     } catch (e) {
//       log('Error marking messages as seen: $e');
//     }
//   }
//
//   /// Handle notification tap
//   void handleNotificationTap(String? payload) {
//     if (payload == null) {
//       log('Notification payload is null');
//       return;
//     }
//
//     try {
//       final data = jsonDecode(payload) as Map<String, dynamic>;
//       log('Notification tap data: $data');
//
//       if (data['title'] == 'Incoming Video Call...' ||
//           data['title'] == 'Incoming Audio Call...') {
//         log('Call notification tapped: $data');
//       } else if (data['isGroup'] == 'true') {
//         FirebaseFirestore.instance
//             .collection(collectionName.groups)
//             .doc(data['groupId'])
//             .get()
//             .then((value) => Get.toNamed(routeName.groupChatMessage,
//                 arguments: value.data()));
//       } else if (data['chatId'] != null && data['userContact'] != null) {
//         final navData = {
//           'chatId': data['chatId'],
//           'data': data['userContact'],
//           'messageId': data['messageId'],
//         };
//         log('Navigating to chat with navData: $navData');
//
//         if (appCtrl.user != null && appCtrl.user['id'] != null) {
//           markMessagesAsSeen(
//               data['chatId'], data['messageId'], appCtrl.user['id']);
//         }
//
//         Get.toNamed(routeName.chatLayout, arguments: navData);
//       } else {
//         log('Missing chatId or userContact in tap payload');
//       }
//     } catch (e) {
//       log('Error parsing notification payload: $e');
//     }
//   }
// }
//
// void notificationTapBackground(NotificationResponse notificationResponse) {
//   log('Background notification tapped: ${notificationResponse.payload}');
//   Get.find<CustomNotificationController>()
//       .handleNotificationTap(notificationResponse.payload);
// }

import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config.dart';

class CustomNotificationController extends GetxController {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  AndroidNotificationChannel? messageChannel;
  AndroidNotificationChannel? callChannel;
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  bool _channelsInitialized = false;

  @override
  void onInit() {
    super.onInit();
    initNotification();
    setupTokenRefreshListener();
  }

  /// Setup FCM token refresh listener
  void setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      updateFCMToken(newToken);
    });
  }

  /// Update FCM token in Firestore
  Future<void> updateFCMToken(String token) async {
    try {
      var user = appCtrl.storage.read(session.user);
      if (user != null && user != "" && user["id"] != null) {
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(user["id"])
            .update({
          'pushToken': token,
          'lastTokenUpdate': DateTime.now().millisecondsSinceEpoch.toString()
        });
        
        // Update local storage
        user['pushToken'] = token;
        await appCtrl.storage.write(session.user, user);
        appCtrl.user = user;
        appCtrl.update();
        
        debugPrint('FCM Token updated in Firestore for user: ${user["id"]}');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  // Initialize notifications
  Future<void> initNotification() async {
    debugPrint('initNotification');

    // Create channels first
    await _createNotificationChannels();
    _channelsInitialized = true;

    // Set foreground notification options
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true
    );

    // Request permissions
    if (Platform.isIOS) {
      final result = await firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        provisional: true,
        sound: true,
      );
      final iosResult = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(result.authorizationStatus == AuthorizationStatus.authorized &&
          iosResult == true
          ? 'FCM: iOS User granted permission'
          : 'FCM: iOS User declined permission');
    } else if (Platform.isAndroid) {
      final result = await firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        provisional: true,
        sound: true,
      );
      debugPrint('Permission result: ${result.authorizationStatus}');
    }

    // Initialize local notifications
    await _initLocalNotification();

    // Handle terminated app state
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('Terminated state message: ${message.data}');
        handleMessage(message);
      }
    });

    // Setup listeners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.data}');
      handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Background message tapped: ${message.data}');
      handleMessage(message);
    });
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    messageChannel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for message notifications.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('message'),
      enableLights: true,
      enableVibration: true,
      showBadge: true,
    );

    callChannel = const AndroidNotificationChannel(
      'call_channel',
      'Call Notifications',
      description: 'This channel is used for call notifications.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('callsound'),
      enableVibration: true,
      showBadge: true,
    );

    final androidPlugin =
    _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.deleteNotificationChannel('high_importance_channel');
    await androidPlugin?.createNotificationChannel(messageChannel!);
    await androidPlugin?.createNotificationChannel(callChannel!);
    debugPrint(
        'Created notification channels: message=${messageChannel!.id}, call=${callChannel!.id}');
  }

  /// Initialize local notifications
  Future<void> _initLocalNotification() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        handleNotificationTap(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  /// Handle incoming messages
  void handleMessage(RemoteMessage message) async {
    final notificationData = message.data;
    final title = message.notification?.title ??
        notificationData['name'] ??
        'New Notification';
    // final body = message.notification?.body ??
    //     notificationData['body'] ??
    //     'You have a new message';
    final isCall = notificationData['title'] == 'Incoming Video Call...' ||
        notificationData['title'] == 'Incoming Audio Call...';

    debugPrint('notificationData: ${jsonEncode(notificationData)}');

    // Suppress call notifications in background
    if (isCall &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      debugPrint('Suppressing call notification in background: $title');
      return;
    }

    // Clear notifications for call end
    if (notificationData['title'] == 'Call Ended' ||
        notificationData['title'] == 'Incoming Call ended') {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('Cleared notifications for Call Ended');
      return;
    }

    // Handle navigation for non-call notifications
    if (!isCall &&
        notificationData['title'] != 'Missed Call' &&
        notificationData['title'] != 'You have new message(s)' &&
        notificationData['title'] != 'Group Message') {
      if (notificationData['isGroup'] == 'true') {
        if (notificationData['groupId'] != null) {
          final groupDoc = await FirebaseFirestore.instance
              .collection(collectionName.groups)
              .doc(notificationData['groupId'])
              .get();
          Get.toNamed(routeName.groupChatMessage, arguments: groupDoc.data());
        } else {
          debugPrint('Missing groupId in group notification');
        }
      } else {
        if (notificationData['chatId'] != null &&
            notificationData['userContact'] != null) {
          debugPrint(
              "notification notificationData:: ${notificationData['chatId']} ${notificationData['userContact']}");
          final data = {
            'chatId': notificationData['chatId'],
            'data': notificationData['userContact'],
            'messageId': notificationData['messageId'] ?? '',
          };
          log("dta notification $data");
          Get.toNamed(routeName.chatLayout, arguments: data);
        } else {
          debugPrint(
              'Missing fields in notification data: chatId=${notificationData['chatId']}, userContact=${notificationData['userContact']}, messageId=${notificationData['messageId']}');
          // Optionally, show a fallback notification or redirect to a default screen
        }
      }
    }

    await showNotification(message);
  }

  // void handleMessage(RemoteMessage message) async {
  //   final notificationData = message.data;
  //   final title = message.notification?.title ??
  //       notificationData['name'] ??
  //       'New Notification';
  //   final body = message.notification?.body ??
  //       notificationData['body'] ??
  //       'You have a new message';
  //   final isCall = notificationData['title'] == 'Incoming Video Call...' ||
  //       notificationData['title'] == 'Incoming Audio Call...';
  //
  //   debugPrint('notificationData: $notificationData');
  //
  //   // Suppress call notifications in background
  //   if (isCall &&
  //       WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
  //     debugPrint('Suppressing call notification in background: $title');
  //     return;
  //   }
  //
  //   // Clear notifications for call end
  //   if (notificationData['title'] == 'Call Ended' ||
  //       notificationData['title'] == 'Incoming Call ended') {
  //     await _flutterLocalNotificationsPlugin.cancelAll();
  //     debugPrint('Cleared notifications for Call Ended');
  //     return;
  //   }
  //
  //   // Handle navigation for non-call notifications
  //   if (!isCall &&
  //       notificationData['title'] != 'Missed Call' &&
  //       notificationData['title'] != 'You have new message(s)' &&
  //       notificationData['title'] != 'Group Message') {
  //     if (notificationData['isGroup'] == 'true') {
  //       if (notificationData['groupId'] != null) {
  //         final groupDoc = await FirebaseFirestore.instance
  //             .collection(collectionName.groups)
  //             .doc(notificationData['groupId'])
  //             .get();
  //         Get.toNamed(routeName.groupChatMessage, arguments: groupDoc.data());
  //       } else {
  //         debugPrint('notification notificationData:: ');
  //       }
  //     }
  //     else {
  //       if (notificationData['chatId'] != null /*&&
  //           notificationData['userContact'] != null*/) {
  //         debugPrint("notification notificationData:: ${notificationData['chatId']} ${notificationData['userContact']}");
  //         final data = {
  //           'chatId': notificationData['chatId'],
  //           'data': notificationData['userContact']??"ipIPmCq1mOgDDgj5t7erNGiRgdx2",
  //           'messageId': notificationData['messageId']??"1748669420755727",
  //         };
  //         log("dta notification ${data}");
  //         Get.toNamed(routeName.chatLayout, arguments: data);
  //       } else {
  //         debugPrint(
  //             'Missing fields in notification data: chatId=${notificationData['chatId']}, userContact=${notificationData['userContact']}');
  //       }
  //     }
  //   }
  //
  //   await showNotification(message);
  // }

  /// Display notification
  Future<void> showNotification(RemoteMessage message) async {
    // Ensure channels are initialized
    if (!_channelsInitialized ||
        messageChannel == null ||
        callChannel == null) {
      debugPrint('Channels not initialized, reinitializing...');
      await _createNotificationChannels();
      _channelsInitialized = true;
      if (messageChannel == null || callChannel == null) {
        debugPrint('Error: Failed to initialize channels');
        return;
      }
    }

    final notification = message.notification;
    final notificationData = message.data;
    final title =
        notification?.title ?? notificationData['name'] ?? 'New Notification';
    final body = notification?.body ??
        notificationData['body'] ??
        'You have a new message';
    final isCall = notificationData['title'] == 'Incoming Video Call...' ||
        notificationData['title'] == 'Incoming Audio Call...';

    final channel = isCall ? callChannel! : messageChannel!;
    final soundName = isCall ? 'callsound' : 'message';

    debugPrint(
        'Showing notification: title=$title, body=$body, isCall=$isCall, sound=$soundName, channel=${channel.id}');

    if (notification != null) {
      final androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: '@mipmap/ic_launcher',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundName),
        fullScreenIntent: isCall,
      );

      final iosDetails = DarwinNotificationDetails(
        sound: soundName,
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(notificationData),
      );
      debugPrint('Notification shown successfully');
    }
  }

  /// Mark messages as seen in Firestore
  Future<void> markMessagesAsSeen(
      String chatId, String? messageId, String currentUserId) async {
    try {
      if (messageId != null) {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .update({'isSeen': true});
        debugPrint('Marked message $messageId as seen in chat $chatId');
      } else {
        final unreadMessages = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('receiverId', isEqualTo: currentUserId)
            .where('isSeen', isEqualTo: false)
            .get();

        for (var doc in unreadMessages.docs) {
          await doc.reference.update({'isSeen': true});
        }
        debugPrint(
            'Marked ${unreadMessages.docs.length} messages as seen in chat $chatId');
      }
    } catch (e) {
      debugPrint('Error marking messages as seen: $e');
    }
  }

  /// Handle notification tap

  void handleNotificationTap(String? payload) {
    if (payload == null) {
      debugPrint('Notification payload is null');
      return;
    }

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      debugPrint('Notification tap data: $data');

      if (data['title'] == 'Incoming Video Call...' ||
          data['title'] == 'Incoming Audio Call...') {
        debugPrint('Call notification tapped: $data');
      } else if (data['isGroup'] == 'true') {
        FirebaseFirestore.instance
            .collection(collectionName.groups)
            .doc(data['groupId'])
            .get()
            .then((value) => Get.toNamed(routeName.groupChatMessage,
            arguments: value.data()));
      } else if (data['chatId'] != null && data['userContact'] != null) {
        final navData = {
          'chatId': data['chatId'],
          'data': data['userContact'],
          'messageId': data['messageId'],
        };
        debugPrint('Navigating to chat with navData: $navData');

        if (appCtrl.user != null && appCtrl.user['id'] != null) {
          markMessagesAsSeen(
              data['chatId'], data['messageId'], appCtrl.user['id']);
        }

        Get.toNamed(routeName.chatLayout, arguments: navData);
      } else {
        debugPrint('Missing chatId or userContact in tap payload');
      }
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }
}

void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('Background notification tapped: ${notificationResponse.payload}');
  Get.find<CustomNotificationController>()
      .handleNotificationTap(notificationResponse.payload);
}

// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
//
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
// import '../../config.dart';
//
// class CustomNotificationController extends GetxController {
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//   AndroidNotificationChannel? messageChannel; // Nullable
//   AndroidNotificationChannel? callChannel; // Nullable
//   FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
//   bool _channelsInitialized = false; // Track initialization
//
//   @override
//   void onInit() {
//     super.onInit();
//     initNotification();
//   }
//
//   // Initialize notifications
//   Future<void> initNotification() async {
//     debugPrint('initNotification');
//
//     // Create channels first
//     await _createNotificationChannels();
//     _channelsInitialized = true;
//
//     // Set foreground notification options
//     await FirebaseMessaging.instance
//         .setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//
//     // Request permissions
//     if (Platform.isIOS) {
//       final result = await firebaseMessaging.requestPermission(
//         alert: true,
//         badge: true,
//         provisional: true,
//         sound: true,
//       );
//       final iosResult = await _flutterLocalNotificationsPlugin
//           .resolvePlatformSpecificImplementation<
//               IOSFlutterLocalNotificationsPlugin>()
//           ?.requestPermissions(
//             alert: true,
//             badge: true,
//             sound: true,
//           );
//       debugPrint(result.authorizationStatus == AuthorizationStatus.authorized &&
//               iosResult == true
//           ? 'FCM: iOS User granted permission'
//           : 'FCM: iOS User declined permission');
//     } else if (Platform.isAndroid) {
//       final result = await firebaseMessaging.requestPermission(
//         alert: true,
//         badge: true,
//         provisional: true,
//         sound: true,
//       );
//       debugPrint("Permission result: ${result.authorizationStatus}");
//     }
//
//     // Initialize local notifications
//     await _initLocalNotification();
//
//     // Handle terminated app state
//     FirebaseMessaging.instance
//         .getInitialMessage()
//         .then((RemoteMessage? message) {
//       if (message != null) {
//         debugPrint("Terminated state message: ${message.data}");
//         handleMessage(message);
//       }
//     });
//
//     // Setup listeners
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       debugPrint("Foreground message received: ${message.data}");
//       handleMessage(message);
//     });
//
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       debugPrint("Background message tapped: ${message.data}");
//       handleMessage(message);
//     });
//   }
//
//   /// Create Android notification channels
//   Future<void> _createNotificationChannels() async {
//     messageChannel = const AndroidNotificationChannel(
//       'high_importance_channel',
//       'High Importance Notifications',
//       description: 'This channel is used for message notifications.',
//       importance: Importance.max,
//       playSound: true,
//       sound: RawResourceAndroidNotificationSound('message'),
//       enableLights: true,
//       enableVibration: true,
//       showBadge: true,
//     );
//
//     callChannel = const AndroidNotificationChannel(
//       'call_channel',
//       'Call Notifications',
//       description: 'This channel is used for call notifications.',
//       importance: Importance.max,
//       playSound: false, // Disable default sound for calls
//       enableVibration: true,
//       showBadge: true,
//     );
//
//     final androidPlugin =
//         _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>();
//     await androidPlugin?.deleteNotificationChannel('high_importance_channel');
//     await androidPlugin?.createNotificationChannel(messageChannel!);
//     await androidPlugin?.createNotificationChannel(callChannel!);
//     debugPrint(
//         "Created notification channels: message=${messageChannel!.id}, call=${callChannel!.id}");
//   }
//
//   /// Initialize local notifications
//   Future<void> _initLocalNotification() async {
//     const androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosSettings = DarwinInitializationSettings();
//     const initSettings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await _flutterLocalNotificationsPlugin.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         debugPrint("Notification clicked: ${response.payload}");
//         handleNotificationTap(response.payload);
//       },
//       onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
//     );
//   }
//
//   /// Handle incoming messages
//   void handleMessage(RemoteMessage message) async {
//     final notificationData = message.data;
//     final title = message.notification?.title ??
//         notificationData['name'] ??
//         'New Notification';
//     final body = message.notification?.body ??
//         notificationData['body'] ??
//         'You have a new message';
//     final isCall = notificationData['title'] == 'Incoming Video Call...' ||
//         notificationData['title'] == 'Incoming Audio Call...';
//
//     debugPrint("notificationData: $notificationData");
//
//     // Suppress call notifications in background
//     if (isCall &&
//         WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
//       debugPrint("Suppressing call notification in background: $title");
//       try {
//         await FlutterRingtonePlayer().play(
//           fromAsset: 'assets/callsound.wav',
//           asAlarm: true,
//           looping: false,
//           volume: 1.0,
//         );
//         debugPrint("Playing call ringtone for 2 seconds (background)");
//         await Future.delayed(const Duration(seconds: 2));
//         await FlutterRingtonePlayer().stop();
//         debugPrint("Stopped call ringtone (background)");
//       } catch (e) {
//         debugPrint("Error playing call ringtone (background): $e");
//       }
//       return;
//     }
//
//     // Clear notifications for call end
//     if (notificationData['title'] == 'Call Ended' ||
//         notificationData['title'] == 'Incoming Call ended') {
//       await _flutterLocalNotificationsPlugin.cancelAll();
//       debugPrint("Cleared notifications for Call Ended");
//       return;
//     }
//
//     // Handle navigation for non-call notifications
//     if (!isCall &&
//         notificationData['title'] != 'Missed Call' &&
//         notificationData['title'] != 'You have new message(s)' &&
//         notificationData['title'] != 'Group Message') {
//       if (notificationData['isGroup'] == 'true') {
//         final groupDoc = await FirebaseFirestore.instance
//             .collection(collectionName.groups)
//             .doc(notificationData['groupId'])
//             .get();
//         Get.toNamed(routeName.groupChatMessage, arguments: groupDoc.data());
//       } else if (notificationData['chatId'] != null &&
//           notificationData['userContact'] != null) {
//         final data = {
//           "chatId": notificationData["chatId"],
//           "data": notificationData["userContact"],
//           "messageId": notificationData["messageId"],
//         };
//         Get.toNamed(routeName.chatLayout, arguments: data);
//       } else {
//         debugPrint("Missing chatId or userContact in notification data");
//       }
//     }
//
//     await showNotification(message);
//   }
//
//   /// Display notification
//   Future<void> showNotification(RemoteMessage message) async {
//     // Ensure channels are initialized
//     if (!_channelsInitialized ||
//         messageChannel == null ||
//         callChannel == null) {
//       debugPrint("Channels not initialized, reinitializing...");
//       await _createNotificationChannels();
//       _channelsInitialized = true;
//       if (messageChannel == null || callChannel == null) {
//         debugPrint("Error: Failed to initialize channels");
//         return;
//       }
//     }
//
//     final notification = message.notification;
//     final notificationData = message.data;
//     final title =
//         notification?.title ?? notificationData['name'] ?? 'New Notification';
//     final body = notification?.body ??
//         notificationData['body'] ??
//         'You have a new message';
//     final isCall = notificationData['title'] == 'Incoming Video Call...' ||
//         notificationData['title'] == 'Incoming Audio Call...';
//
//     final channel = isCall ? callChannel! : messageChannel!;
//     final soundName = isCall ? null : 'message';
//
//     debugPrint(
//         "Showing notification: title=$title, body=$body, isCall=$isCall, sound=$soundName, channel=${channel.id}");
//
//     // Handle call notifications with flutter_ringtone_player
//     if (isCall) {
//       try {
//         debugPrint("playing call ringtone: $isCall");
//         await FlutterRingtonePlayer().play(
//           fromAsset: 'assets/callsound.wav',
//           asAlarm: true,
//           looping: false,
//           volume: 1.0,
//         );
//         debugPrint("Playing call ringtone for 2 seconds");
//         await Future.delayed(const Duration(seconds: 2));
//         await FlutterRingtonePlayer().stop();
//         debugPrint("Stopped call ringtone");
//       } catch (e) {
//         debugPrint("Error playing call ringtone: $e");
//       }
//     }
//
//     if (notification != null) {
//       final androidDetails = AndroidNotificationDetails(
//         channel.id,
//         channel.name,
//         channelDescription: channel.description,
//         icon: '@mipmap/ic_launcher',
//         importance: Importance.max,
//         priority: Priority.high,
//         playSound: !isCall,
//         sound: isCall ? null : RawResourceAndroidNotificationSound('message'),
//         fullScreenIntent: isCall,
//       );
//
//       final iosDetails = DarwinNotificationDetails(
//         sound: isCall ? 'callsound' : 'message',
//         presentSound: true,
//         presentAlert: true,
//         presentBadge: true,
//       );
//
//       final notificationDetails = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );
//
//       await _flutterLocalNotificationsPlugin.show(
//         notification.hashCode,
//         title,
//         body,
//         notificationDetails,
//         payload: jsonEncode(notificationData),
//       );
//       debugPrint("Notification shown successfully");
//     }
//   }
//
//   /// Mark messages as seen in Firestore
//   Future<void> markMessagesAsSeen(
//       String chatId, String? messageId, String currentUserId) async {
//     try {
//       if (messageId != null) {
//         await FirebaseFirestore.instance
//             .collection('chats')
//             .doc(chatId)
//             .collection('messages')
//             .doc(messageId)
//             .update({'isSeen': true});
//         debugPrint("Marked message $messageId as seen in chat $chatId");
//       } else {
//         final unreadMessages = await FirebaseFirestore.instance
//             .collection('chats')
//             .doc(chatId)
//             .collection('messages')
//             .where('receiverId', isEqualTo: currentUserId)
//             .where('isSeen', isEqualTo: false)
//             .get();
//
//         for (var doc in unreadMessages.docs) {
//           await doc.reference.update({'isSeen': true});
//         }
//         debugPrint(
//             "Marked ${unreadMessages.docs.length} messages as seen in chat $chatId");
//       }
//     } catch (e) {
//       debugPrint("Error marking messages as seen: $e");
//     }
//   }
//
//   /// Handle notification tap
//   void handleNotificationTap(String? payload) {
//     if (payload == null) {
//       debugPrint("Notification payload is null");
//       return;
//     }
//
//     try {
//       final data = jsonDecode(payload) as Map<String, dynamic>;
//       debugPrint("Notification tap data: $data");
//
//       if (data['title'] == 'Incoming Video Call...' ||
//           data['title'] == 'Incoming Audio Call...') {
//         debugPrint("Call notification tapped: $data");
//       } else if (data['isGroup'] == 'true') {
//         FirebaseFirestore.instance
//             .collection(collectionName.groups)
//             .doc(data['groupId'])
//             .get()
//             .then((value) => Get.toNamed(routeName.groupChatMessage,
//                 arguments: value.data()));
//       } else if (data['chatId'] != null && data['userContact'] != null) {
//         final navData = {
//           "chatId": data["chatId"],
//           "data": data["userContact"],
//           "messageId": data["messageId"],
//         };
//         debugPrint("Navigating to chat with navData: $navData");
//
//         if (appCtrl.user != null && appCtrl.user["id"] != null) {
//           markMessagesAsSeen(
//               data["chatId"], data["messageId"], appCtrl.user["id"]);
//         }
//
//         Get.toNamed(routeName.chatLayout, arguments: navData);
//       } else {
//         debugPrint("Missing chatId or userContact in tap payload");
//       }
//     } catch (e) {
//       debugPrint("Error parsing notification payload: $e");
//     }
//   }
// }
//
// void notificationTapBackground(NotificationResponse notificationResponse) {
//   debugPrint("Background notification tapped: ${notificationResponse.payload}");
//   Get.find<CustomNotificationController>()
//       .handleNotificationTap(notificationResponse.payload);
// }
