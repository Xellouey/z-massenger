import 'dart:convert';
import 'dart:developer';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../config.dart';
import '../../models/usage_control_model.dart';
import '../../models/user_setting_model.dart';
import '../common_controllers/contact_controller.dart';
import '../recent_chat_controller.dart';

class SplashController extends GetxController {
  SharedPreferences? pref;
  DocumentSnapshot<Map<String, dynamic>>? rmk, uck;

  @override
  void onReady() async {
    await getAdminPermission();

    var user = appCtrl.storage.read(session.user);
    appCtrl.user = user;
    appCtrl.pref = pref;
    log("user :$user");

    bool permission = appCtrl.storage.read(session.contactPermission) ?? false;
    log("permission :$permission");
    if (permission) {
      if (user != null) {
        final ContactProvider contactProvider =
        Provider.of<ContactProvider>(Get.context!, listen: false);
        bool isContact = await contactProvider.checkForLocalSaveOrNot();
        log("isContact ;$isContact");
        if (isContact) {
          contactProvider.loadContactsFromLocal();
        } else {
          contactProvider.fetchContacts(
            appCtrl.user["phone"],
          );
        }
        /* final FetchContactController registerAvailableContact =
            Provider.of<FetchContactController>(Get.context!, listen: false);
        registerAvailableContact.fetchContacts(
            Get.context!, appCtrl.user["phone"], pref ?? appCtrl.pref!, true);*/
      }
    }
    bool isOnBoard = appCtrl.storage.read('onBoard') ?? false;
    // bool isInvite = appCtrl.storage.read('skip') ?? false;
    appCtrl.update();
    update();
    final RecentChatController recentChatController =
    Provider.of<RecentChatController>(Get.context!, listen: false);

    if (user != null) {
      recentChatController.checkChatList(pref!);
    }

    appCtrl.update();
    Get.forceAppUpdate();
    dynamic lan;
    await FirebaseFirestore.instance
        .collection(collectionName.languages)
        .doc(collectionName.defaultLanguage)
        .get()
        .then((value) {
      if (value.exists) {
        lan = value.data()!["language"];
      }
    });
    update();
    bool isBiometric = appCtrl.storage.read(session.isBiometric) ?? false;
    appCtrl.isBiometric = isBiometric;
    fetchDataFromRemoteConfig();
    
    // Request notification permission for Android 13+ (API 33+)
    try {
      PermissionStatus status = await Permission.notification.status;
      if (!status.isGranted) {
        status = await Permission.notification.request();
        if (status.isGranted) {
          debugPrint("Notification permission granted");
        } else if (status.isDenied) {
          debugPrint("Notification permission denied");
        } else if (status.isPermanentlyDenied) {
          debugPrint("Notification permission permanently denied - user must enable in settings");
        }
      } else {
        debugPrint("Notification permission already granted");
      }
    } catch (e) {
      debugPrint("Failed to request notification permission: $e");
    }
    update();

    /*try {
      int count = 0;
      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .get()
          .then(
        (value) async {
          log("value.docs. :${value.docs.length}");
          if (value.docs.isNotEmpty) {
            for (var d in value.docs) {
              // count++;
              await FirebaseFirestore.instance
                  .collection(collectionName.calls)
                  .doc(d.id)
                  .delete();
              log("COUNT :${value.docs}");
              await FirebaseFirestore.instance
                  .collection(collectionName.users)
                  .doc(d.id)
                  .delete();
              log("COUNT :${d.id}");
            }
          } else {
            log("ERROR WHILE DELETE");
          }
        },
      ).onError(
        (error, stackTrace) {
          log("WWWWW : $error");
        },
      );

      await FirebaseFirestore.instance
          .collection(collectionName.groups)
          .get()
          .then(
        (value) async {
          log("vGROUPalue.docs. :${value.docs.length}");
          if (value.docs.isNotEmpty) {
            for (var d in value.docs) {
              await FirebaseFirestore.instance
                  .collection(collectionName.groups)
                  .doc(d.id)
                  .delete();
            }
          } else {
            log("ERROR WHILE DELETE");
          }
        },
      ).onError(
        (error, stackTrace) {
          log("WWWWW : $error");
        },
      );
    } on FirebaseException catch (e) {
      log("ERROR : $e");
    }*/

    Future.delayed(const Duration(milliseconds: 2300), () async {
      if (isOnBoard) {
        if (user == "" || user == null) {
          Get.offAllNamed(routeName.loginScreen, arguments: pref);
        } else {
          if (user['email'] == null || user['name'] == "") {
            Get.offAllNamed(routeName.loginScreen, arguments: pref);
          } else {
            if (isBiometric == true) {
              LocalAuthentication auth = LocalAuthentication();
              bool authenticated = false;
              try {
                authenticated = await auth.authenticate(
                    localizedReason: "Scan your finger to authenticate",
                    options: const AuthenticationOptions(
                        useErrorDialogs: true,
                        stickyAuth: true,
                        biometricOnly: true));
                log("message:::${appFonts.deviceNotSupported.tr}");
                Get.offAllNamed(routeName.dashboard, arguments: pref);
                return authenticated;
              } on PlatformException {
                log("message:::${appFonts.deviceNotSupported.tr}");
                flutterAlertMessage(msg: appFonts.deviceNotSupported.tr);
                return false;
              }
              /*   bool isAuth = await msgCtrl.authenticate();
              if (isAuth) {
                Get.toNamed(routeName.fingerScannerScreen, arguments: pref);
              } else {
                snackBar("Failed to Authenticate");
              } */
              /*    Get.toNamed(routeName.fingerScannerScreen, arguments: pref); */
            } else {
              log("-=-=-=-=-=-=-=-=-=${appCtrl.storage.read(session.locale)}', '${appCtrl.storage.read(session.countryCode)}");
              Get.offAllNamed(routeName.dashboard, arguments: pref);
            }
          }
        }
      } else {
        Get.offAllNamed(routeName.onBoardingScreen, arguments: pref);
      }
      update();
    });

    String lanCode = lan["code"].toString().split("_")[0];
    String countryCode = lan["code"].toString().split("_")[1];

    Locale? locale = Locale(lanCode, countryCode);

    //language
    var language = await appCtrl.storage.read(session.locale) ?? lanCode;
    debugPrint("LANGUAGE1 $language");
    appCtrl.languageVal = language;
    Get.updateLocale(Locale('${appCtrl.storage.read(session.locale)}',
        '${appCtrl.storage.read(session.countryCode)}') /*  locale */);
    appCtrl.locale = Locale('${appCtrl.storage.read(session.locale)}',
        '${appCtrl.storage.read(session.countryCode)}') /*  locale */;
    log("message12121212====> ${appCtrl.locale}");
    Get.updateLocale(Locale('${appCtrl.storage.read(session.locale)}',
        '${appCtrl.storage.read(session.countryCode)}') /*  locale */);
    update();
    bool isRtlSave = appCtrl.storage.read(session.isRTL) ?? false;
    bool isThemeSave = appCtrl.storage.read(session.isDarkMode) ?? false;
    appCtrl.isRTL = isRtlSave;
    ThemeService().switchTheme(isThemeSave);
    appCtrl.isTheme = isThemeSave;

    final agoraToken = await FirebaseFirestore.instance
        .collection(collectionName.config)
        .doc(collectionName.agoraToken)
        .get();
    await appCtrl.storage.write(session.agoraToken, agoraToken.data());

    firebaseCtrl.statusDeleteAfter24Hours();
    firebaseCtrl.deleteForAllUsers();
    // TODO: implement onReady
    super.onReady();
  }

  getAdminPermission() async {
    final usageControls = rmk;
    debugPrint("dfddddddd${usageControls!.data()}");
    appCtrl.usageControlsVal =
        UsageControlModel.fromJson(usageControls!.data()!);

    appCtrl.update();
    appCtrl.storage.write(session.usageControls, usageControls.data());

    final userAppSettings = uck;
    log("admin 4: ${userAppSettings!.data()}");
    appCtrl.userAppSettingsVal =
        UserAppSettingModel.fromJson(userAppSettings.data()!);
    final agoraToken = await FirebaseFirestore.instance
        .collection(collectionName.config)
        .doc(collectionName.agoraToken)
        .get();
    await appCtrl.storage.write(session.agoraToken, agoraToken.data());

    update();
    appCtrl.update();
    Get.forceAppUpdate();
  }

  fetchDataFromRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    // Configure settings for remote config fetch
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(minutes: 5)));

    update();
    // Fetch and activate remote config data
    await remoteConfig.fetchAndActivate();
    String defaultRegulationsHelpURL =
    remoteConfig.getString('notification_url');
    appCtrl.notificationUrl = defaultRegulationsHelpURL;

    String firebaseCredString = remoteConfig.getValue("firebase_credentials").asString();
    if (firebaseCredString.isNotEmpty) {
      try {
        dynamic mapValues = json.decode(firebaseCredString);
        appCtrl.firebaseCred = mapValues;
        log("appCtrl.firebaseCred :${appCtrl.firebaseCred}");
      } catch (e) {
        log("Error parsing firebase_credentials: $e");
        appCtrl.firebaseCred = {};
      }
    } else {
      log("firebase_credentials is empty in Remote Config");
      appCtrl.firebaseCred = {};
    }
    appCtrl.update();
  }
}
