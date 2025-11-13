import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'common/extension/tklmn.dart';
import 'common/languages/index.dart';
import 'config.dart';
import 'controllers/common_controllers/contact_controller.dart';
import 'controllers/common_controllers/firebase_common_controller.dart';
import 'controllers/common_controllers/notification_controller.dart';
import 'controllers/recent_chat_controller.dart';
import 'screens/auth_screens/splash_screen/splash_screen.dart';

const encryptedKey = "MyZ32lengthENCRYPTKEY12345678901"; // Exactly 32 characters for AES-256

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  if (Platform.isAndroid) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA0BxptiYnC9Mhx99nDygAhDfCq_kVnlxM",
        appId: "1:802822444297:android:2ed6be3ce2d27268672fd8",
        storageBucket: "z-messenger-bc7fd.firebasestorage.app",
        messagingSenderId: "802822444297",
        projectId: "z-messenger-bc7fd",
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA0BxptiYnC9Mhx99nDygAhDfCq_kVnlxM",
        appId: "1:802822444297:android:2ed6be3ce2d27268672fd8",
        storageBucket: "z-messenger-bc7fd.firebasestorage.app",
        messagingSenderId: "802822444297",
        projectId: "z-messenger-bc7fd",
      ),
    );
  }

  // Инициализация App Check
  try {
    if (kDebugMode) {
      // В debug режиме включаем вывод токена в логи
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      // Получаем и логируем токен
      try {
        final token = await FirebaseAppCheck.instance.getToken();
        log('=== APP CHECK DEBUG TOKEN ===> ${token}');
      } catch (e) {
        log('⚠️ App Check token error (add token to Firebase Console): $e');
      }
    } else {
      // В release режиме используем Play Integrity
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
    }
  } catch (e) {
    log('⚠️ App Check initialization error: $e');
    // Продолжаем работу без App Check
  }

  cameras = await availableCameras();
  // Get.put(LoadingController());
  // Set the background messaging handler early on, as a named top-level function
  Get.put(AppController());
  Get.put(FirebaseCommonController());
  Get.put(CustomNotificationController());
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: appCtrl.appTheme.trans,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // TODO: implement initState
    final noti = Get.find<CustomNotificationController>();
    noti.initNotification();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    lockScreenPortrait();
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, AsyncSnapshot<SharedPreferences> snapData) {
        if (snapData.hasData) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => RecentChatController()),
              ChangeNotifierProvider(create: (_) => ContactProvider()),
            ],
            child: GetMaterialApp(
              builder: (context, widget) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.0)),
                  child: widget!,
                );
              },
              debugShowCheckedModeBanner: false,
              translations: Language(),
              locale: const Locale('ru', 'RU'),
              fallbackLocale: const Locale('ru', 'RU'),
              title: appFonts.Z.tr,
              home: FutureBuilder(
                future: Future.wait([
                  FirebaseFirestore.instance
                      .collection(collectionName.config)
                      .doc(collectionName.usageControls)
                      .get(),
                  FirebaseFirestore.instance
                      .collection(collectionName.config)
                      .doc(collectionName.userAppSettings)
                      .get(),
                ]),
                builder: (context, AsyncSnapshot<List<DocumentSnapshot<Map<String, dynamic>>>> snapshot) {
                  if (snapshot.hasData) {
                    return SplashScreen(
                      pref: snapData.data,
                      rm: snapshot.data![0],
                      uc: snapshot.data![1],
                    );
                  }
                  return Scaffold(
                    backgroundColor: Colors.black,
                    body: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                        ),
                        Image.asset(
                          eImageAssets.icLauncherPlaystore,
                          height: 150,
                          width: 150,
                        ),
                      ],
                    ),
                  );
                },
              ),
              getPages: appRoute.getPages,
              theme: AppTheme.fromType(ThemeType.light).themeData,
              darkTheme: AppTheme.fromType(ThemeType.dark).themeData,
              themeMode: ThemeService().theme,
            ),
          );
        } else {
          log("NO DATA ");
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => RecentChatController()),
              ChangeNotifierProvider(create: (_) => ContactProvider()),
            ],
            child: MaterialApp(
              theme: AppTheme.fromType(ThemeType.light).themeData,
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Image.asset(
                    eImageAssets.icLauncherPlaystore,
                    height: 150,
                    width: 150,
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  lockScreenPortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  if (Platform.isAndroid) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA0BxptiYnC9Mhx99nDygAhDfCq_kVnlxM",
        appId: "1:802822444297:android:2ed6be3ce2d27268672fd8",
        storageBucket: "z-messenger-bc7fd.firebasestorage.app",
        messagingSenderId: "802822444297",
        projectId: "z-messenger-bc7fd",
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA0BxptiYnC9Mhx99nDygAhDfCq_kVnlxM",
        appId: "1:802822444297:android:2ed6be3ce2d27268672fd8",
        storageBucket: "z-messenger-bc7fd.firebasestorage.app",
        messagingSenderId: "802822444297",
        projectId: "z-messenger-bc7fd",
      ),
    );
  }

  log('🔔 Background notification received: ${message.data}');

  // Determine if this is a call notification
  final isCall = message.data['title'] == 'Incoming Audio Call...' ||
      message.data['title'] == 'Incoming Video Call...';

  // Use the correct channel ID that matches notification_controller.dart and strings.xml
  final channelId = isCall ? 'call_channel' : 'high_importance_channel';
  final soundName = isCall ? 'callsound' : 'message';

  log('🔔 Using channel: $channelId, sound: $soundName');

  AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId,
    isCall ? 'Call Notifications' : 'High Importance Notifications',
    description: isCall
        ? 'This channel is used for call notifications.'
        : 'This channel is used for message notifications.',
    playSound: true,
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound(soundName),
    enableVibration: true,
    enableLights: true,
    showBadge: true,
  );

  final notifications = CustomNotificationController();
  await notifications.initNotification();
  notifications.showNotification(message);
}
