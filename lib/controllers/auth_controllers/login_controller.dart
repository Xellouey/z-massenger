import 'dart:developer';
import 'dart:io';
import 'package:chatzy/config.dart';
import 'package:chatzy/utils/snack_and_dialogs_utils.dart';
import 'package:country_list_pick/support/code_countries_en.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../../models/usage_control_model.dart';
import '../../models/user_setting_model.dart';
import '../common_controllers/contact_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../recent_chat_controller.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

class LoginController extends GetxController {
  TextEditingController numberController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  GlobalKey<FormState> mobileGlobalKey = GlobalKey<FormState>();
  GlobalKey<FormState> otpGlobalKey = GlobalKey<FormState>();
  bool isLoading = false, isContactLoad = false;
  String? userName, verificationCode, resendCodeID;
  FirebaseAuth auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> contactsData = [];
  List<Map<String, dynamic>> unRegisterContactData = [];
  SharedPreferences? pref;
  String dialCode = '+91';
  bool isDemoMode = false; // Demo mode flag

  onTapOtp() async {
    if (mobileGlobalKey.currentState!.validate()) {
      isLoading = true;
      update();
      debugPrint("log 1 ${numberController.text.toString()}");
      appCtrl.pref = pref;
      appCtrl.update();

      // Check if demo mode is enabled
      await checkDemoMode();
      log("isDemoMode::${isDemoMode}");
      if (isDemoMode) {
        // Demo mode: Skip OTP verification, directly show OTP screen
        verificationCode = "demo_verification_id";
        isLoading = false;
        update();
        log("Demo mode active - any OTP will work");
      } else if (numberController.text == '9612345678') {
        // Special test number logic (existing)
        await handleSpecialTestNumber();
      } else {
        // Normal Firebase OTP verification
        await sendOtpToPhoneNumber();
      }
    }
  }

  // Check if demo mode is enabled from Firebase config/usageControls
  checkDemoMode() async {
    try {
      final usageControlsDoc = await FirebaseFirestore.instance
          .collection(collectionName.config)
          .doc(collectionName.usageControls)
          .get();

      if (usageControlsDoc.exists && usageControlsDoc.data() != null) {
        isDemoMode = usageControlsDoc.data()!['demoMode'] ?? false;
        log("Demo mode status: $isDemoMode");
      }
    } catch (e) {
      log("Error checking demo mode: $e");
      isDemoMode = false;
    }
  }

  // Special test number handling (existing logic)
  handleSpecialTestNumber() async {
    log("Special test number: ${"${dialCode}9612345678"}");
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .where("phone", isEqualTo: "${dialCode}9612345678")
        .get()
        .then((value) async {
      log("DATA Length: ${value.docs.length}");
      if (value.docs.isNotEmpty) {
        if (value.docs[0].data()["name"] == "" ||
            value.docs[0].data()["name"] == null) {
          await appCtrl.storage.write(session.user, value.docs[0].data());
          appCtrl.storage.write(session.dialCode, dialCode);
          Get.offAllNamed(routeName.profileSetupScreen, arguments: {
            "resultData": value.docs[0].data(),
            "isPhoneLogin": true,
            "isOnlyLogin": true,
            "pref": pref,
            'dialCode': dialCode
          });
        } else {
          await appCtrl.storage.write(session.user, value.docs[0].data());
          appCtrl.storage.write(session.id, value.docs[0].data()["id"]);
          appCtrl.user = value.docs[0].data();
          appCtrl.update();
          homeNavigation(value.docs[0].data());
        }
      } else {
        isLoading = false;
        update();
        log("Special number user not found");
      }
    });
  }

  // Send OTP to phone number (existing logic)
  sendOtpToPhoneNumber() async {
    debugPrint(
        "NUMBER : '${dialCode ?? "+91"}${numberController.text.toString()}'");
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '$dialCode${numberController.text.toString()}',
      verificationCompleted: (PhoneAuthCredential credential) {
        debugPrint("log 4 $credential");
        isLoading = false;
        update();
      },
      timeout: const Duration(seconds: 60),
      verificationFailed: (FirebaseAuthException e) {
        debugPrint("log 5 $e");
        isLoading = false;
        update();
        snackBar(
          e.message,
          context: Get.context!,
        );
      },
      codeSent: (String verificationId, int? resendToken) async {
        resendCodeID = verificationId;
        verificationCode = verificationId;
        debugPrint("log 2 $verificationId");
        var phoneUser = FirebaseAuth.instance.currentUser;
        debugPrint("log 3 $phoneUser");
        userName = phoneUser?.phoneNumber;
        isLoading = false;
        update();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        isLoading = false;
        update();
        log("Code auto retrieval timeout");
      },
    );
  }

  resendCode() async {
    if (isDemoMode) {
      // In demo mode, just show that code was sent
      snackBar("Demo mode: OTP sent successfully!");
      return;
    }

    // Normal resend code logic
    isLoading = true;
    update();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '${dialCode ?? "+91"}${numberController.text.toString()}',
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {},
      codeSent: (String verificationId, int? resendToken) async {
        resendCodeID = verificationId;
        verificationCode = verificationId;
        debugPrint("log 2 $resendCodeID");
        var phoneUser = FirebaseAuth.instance.currentUser;
        debugPrint("log 3 $phoneUser");
        userName = phoneUser?.phoneNumber;
        isLoading = false;
        update();
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
    update();
  }

  //on verify code
  onTapValidateOtp() async {
    log("otpGlobalKey.currentState!.validate() :${otpGlobalKey.currentState!.validate()}");
    if (otpGlobalKey.currentState!.validate()) {
      try {
        isLoading = true;
        update();

        if (isDemoMode) {
          // Demo mode: Accept any OTP
          await handleDemoOtpVerification();
        } else {
          // Normal mode: Validate with Firebase
          PhoneAuthCredential credential = PhoneAuthProvider.credential(
              verificationId: verificationCode!,
              smsCode: otpController.text.toString());
          await auth.signInWithCredential(credential);
          
          // Check if user exists in Firestore
          await handleNormalOtpVerification();
        }

        isLoading = false;
        update();
      } catch (e) {
        isLoading = false;
        update();
        flutterAlertMessage(
            msg: isDemoMode ? 'Demo login failed' : 'Invalid code');
      }
    }
  }

  //on form submit
  void onFormSubmitted() async {
    log("otpGlobalKey.currentState!.validate() : ${otpGlobalKey.currentState!.validate()}");
    if (otpGlobalKey.currentState!.validate()) {
      isLoading = true;
      update();

      if (isDemoMode) {
        // Demo mode: Accept any OTP
        await handleDemoOtpVerification();
      } else {
        // Normal OTP verification
        await handleNormalOtpVerification();
      }
    }
    update();
  }

  // Handle demo mode OTP verification (accept any OTP)
  handleDemoOtpVerification() async {
    try {
      log("Demo mode: Processing OTP verification");
      // Check if the entered OTP is exactly "123456"
      if (otpController.text.trim() != "123456") {
        log("Demo mode: Invalid OTP entered - ${otpController.text}");
        isLoading = false;
        update();
        flutterAlertMessage(msg: 'Demo mode: Please enter 123456 as OTP');
        return;
      }
      // Check if user exists or create new one
      String fullPhoneNumber = "$dialCode${numberController.text}";

      final userQuery = await FirebaseFirestore.instance
          .collection(collectionName.users)
          .where("phone", isEqualTo: fullPhoneNumber)
          .get();

      if (userQuery.docs.isNotEmpty) {
        // User exists
        Map<String, dynamic> userData = userQuery.docs[0].data();
        log("Demo mode: Existing user found");
        await proceedWithUserData(userData);
      } else {
        // Create new demo user
        log("Demo mode: Creating new demo user");
        await createNewDemoUser();
      }

      isLoading = false;
      update();
    } catch (e) {
      log("Demo OTP verification error: $e");
      isLoading = false;
      update();
      flutterAlertMessage(msg: 'Demo login failed: ${e.toString()}');
    }
  }

  // Create new demo user during OTP verification
  createNewDemoUser() async {
    try {
      String demoUserId =
          FirebaseFirestore.instance.collection('users').doc().id;
      String fullPhoneNumber = "$dialCode${numberController.text}";

      final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
      String? token = await firebaseMessaging.getToken();

      Map<String, dynamic> newUserData = {
        'id': demoUserId,
        'image': "",
        'name': "",
        'pushToken': token ?? "",
        'status': "Online",
        'dialCode': dialCode,
        "email": "",
        "deviceName": appCtrl.deviceName,
        'phone': fullPhoneNumber,
        'phoneRaw': numberController.text,
        "dialCodePhoneList":
            phoneList(phone: numberController.text, dialCode: dialCode),
        "isActive": true,
        "device": appCtrl.device,
        "statusDesc": "Hello, I am using Z",
        "createdDate": DateTime.now().millisecondsSinceEpoch,
        "isDemoUser": true // Mark as demo user
      };

      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(demoUserId)
          .set(newUserData);

      log("Demo user created with ID: $demoUserId");
      await proceedWithUserData(newUserData);
    } catch (e) {
      log("Error creating demo user: $e");
      throw e;
    }
  }

  // Proceed with user data (common logic for both existing and new users)
  proceedWithUserData(Map<String, dynamic> userData) async {
    appCtrl.pref = pref;
    appCtrl.update();

    if (userData["name"] == "" || userData["name"] == null) {
      await appCtrl.storage.write(session.user, userData);
      appCtrl.storage.write(session.dialCode, dialCode);
      Get.offAllNamed(routeName.profileSetupScreen, arguments: {
        "resultData": userData,
        "isPhoneLogin": true,
        "isOnlyLogin": true,
        "pref": pref,
        'dialCode': dialCode,
        'phone': numberController.text
      });
    } else {
      await appCtrl.storage.write(session.user, userData);
      appCtrl.storage.write(session.id, userData["id"]);
      appCtrl.user = userData;
      appCtrl.update();
      homeNavigation(userData);
    }
  }

  // Handle normal OTP verification (existing logic)
  handleNormalOtpVerification() async {
    debugPrint("verificationCode : $verificationCode");
    PhoneAuthCredential authCredential = PhoneAuthProvider.credential(
        verificationId: verificationCode!, smsCode: otpController.text);

    auth
        .signInWithCredential(authCredential)
        .then((UserCredential value) async {
      debugPrint("value : ${value.user}");
      if (value.user != null) {
        User user = value.user!;
        appCtrl.pref = pref;
        appCtrl.update();
        try {
          FirebaseFirestore.instance
              .collection(collectionName.users)
              .where("id", isEqualTo: user.uid)
              .limit(1)
              .get()
              .then((value) async {
            dynamic resultData = await getUserData(user);
            debugPrint("checkkkkkk : ${value.docs.isEmpty}");
            if (value.docs.isNotEmpty) {
              debugPrint("NAME : ${value.docs[0].data()}");
              if (value.docs[0].data()["name"] == "") {
                await appCtrl.storage.write(session.user, resultData);
                appCtrl.storage.write(session.dialCode, dialCode);
                Get.offAllNamed(routeName.profileSetupScreen, arguments: {
                  "resultData": resultData,
                  "isPhoneLogin": true,
                  "isOnlyLogin": true,
                  "pref": pref,
                  'dialCode': dialCode,
                  'phone': numberController.text
                });
              } else {
                // Update FCM token for existing user on re-login
                final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
                String? token = await firebaseMessaging.getToken();
                
                if (token != null) {
                  await FirebaseFirestore.instance
                      .collection(collectionName.users)
                      .doc(value.docs[0].data()["id"])
                      .update({
                    'pushToken': token,
                    'status': 'Online',
                    'isActive': true,
                    'lastTokenUpdate': DateTime.now().millisecondsSinceEpoch.toString()
                  });
                  
                  debugPrint('FCM Token updated on re-login: $token');
                }
                
                // Fetch updated user data
                final updatedUser = await FirebaseFirestore.instance
                    .collection(collectionName.users)
                    .doc(value.docs[0].data()["id"])
                    .get();
                
                await appCtrl.storage.write(session.user, updatedUser.data());
                appCtrl.storage.write(session.id, updatedUser.data()?["id"]);
                appCtrl.user = updatedUser.data();
                appCtrl.update();
                homeNavigation(updatedUser.data());
              }
            } else {
              debugPrint("check1 : ${value.docs.isEmpty}");
              debugPrint("DATA NATHIII");
              if (appCtrl.usageControlsVal!.allowUserSignup!) {
                await userRegister(user);
                dynamic resultData = await getUserData(user);
                debugPrint("RESULTDATA ${resultData["name"]}");
                appCtrl.storage.write(session.dialCode, dialCode);
                if (resultData["name"] == "") {
                  debugPrint("DATA NATHIII WITH NAME");
                  appCtrl.user = resultData;
                  appCtrl.update();
                  await appCtrl.storage.write(session.user, resultData);
                  Get.offAllNamed(routeName.profileSetupScreen, arguments: {
                    "resultData": resultData,
                    "isPhoneLogin": true,
                    "isOnlyLogin": true,
                    "pref": pref,
                    'dialCode': dialCode,
                    'phone': numberController.text
                  });

                  update();
                } else {
                  debugPrint("DATA NAME READ");
                  await appCtrl.storage
                      .write(session.user, value.docs[0].data());
                  appCtrl.storage.write(session.id, value.docs[0].data()["id"]);
                  appCtrl.user = value.docs[0].data();
                  appCtrl.update();
                  appCtrl.storage.write(session.dialCode, dialCode);
                  homeNavigation(resultData);
                }
              } else {
                snackBar("New Register Not Allow to create Account");
              }
            }
            isLoading = false;
            update();
          }).catchError((err) {
            debugPrint("get : $err");
          });
        } on FirebaseAuthException catch (e) {
          debugPrint("get firebase : $e");
        }
      } else {
        isLoading = false;
        update();
        flutterAlertMessage(msg: appFonts.somethingWentWrong);
      }
    }).catchError((error) {
      isLoading = false;
      update();
      debugPrint("err : ${error.toString()}");
      flutterAlertMessage(msg: error.toString());
    });
  }

  //get data
  Future<Object?> getUserData(User user) async {
    final result = await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(user.uid)
        .get();
    dynamic resultData;
    if (result.exists) {
      Map<String, dynamic>? data = result.data();
      resultData = data;
      return resultData;
    }
    return resultData;
  }

  //user register
  userRegister(User user) async {
    log(" : $user");
    try {
      final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
      firebaseMessaging.getToken().then((token) async {
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(user.uid)
            .set({
          'id': user.uid,
          'image': "",
          'name': "",
          'pushToken': token,
          'status': "Offline",
          'dialCode': dialCode,
          "email": user.email,
          "deviceName": appCtrl.deviceName,
          'phone': "$dialCode${numberController.text}",
          'phoneRaw': numberController.text,
          "dialCodePhoneList":
              phoneList(phone: numberController.text, dialCode: dialCode),
          "isActive": true,
          "device": appCtrl.device,
          "statusDesc": "Hello, I am using Z",
          "createdDate": DateTime.now().millisecondsSinceEpoch,
          "isDemoUser": false // Normal user
        }).catchError((err) {
          debugPrint("fir : $err");
        });
      });
    } on FirebaseAuthException catch (e) {
      debugPrint("firebase : $e");
    }
  }

  getAdminPermission() async {
    final usageControls = await FirebaseFirestore.instance
        .collection(collectionName.config)
        .doc(collectionName.usageControls)
        .get();

    appCtrl.usageControlsVal =
        UsageControlModel.fromJson(usageControls.data()!);

    appCtrl.storage.write(session.usageControls, usageControls.data());
    update();
    final userAppSettings = await FirebaseFirestore.instance
        .collection(collectionName.config)
        .doc(collectionName.userAppSettings)
        .get();
    appCtrl.userAppSettingsVal =
        UserAppSettingModel.fromJson(userAppSettings.data()!);
    final agoraToken = await FirebaseFirestore.instance
        .collection(collectionName.config)
        .doc(collectionName.agoraToken)
        .get();
    await appCtrl.storage.write(session.agoraToken, agoraToken.data());
    update();
    appCtrl.update();
  }

  contactPermissions(user) {
    showDialog(
        context: Get.context!,
        builder: (context) {
          return AlertDialog(
              contentPadding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(AppRadius.r8))),
              backgroundColor: appCtrl.appTheme.white,
              titlePadding: const EdgeInsets.all(Insets.i20),
              title: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Icon(CupertinoIcons.multiply, color: appCtrl.appTheme.txt)
                      .inkWell(onTap: () {
                    isLoading = false;
                    update();
                    Get.back();
                  })
                ])
              ]),
              content: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      eImageAssets.contactBg,
                      height: Sizes.s130,
                      width: Sizes.s180,
                    ),
                    const VSpace(Sizes.s30),
                    Text(appFonts.contactList.tr,
                            style: GoogleFonts.manrope(
                                color: appCtrl.appTheme.darkText,
                                fontWeight: FontWeight.w600,
                                fontSize: 16))
                        .marginSymmetric(horizontal: Insets.i12),
                    const VSpace(Sizes.s12),
                    Text(appFonts.contactPer.tr,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                                color: appCtrl.appTheme.greyText,
                                fontWeight: FontWeight.w400,
                                fontSize: 12))
                        .marginSymmetric(horizontal: Insets.i12),
                    const VSpace(Sizes.s15),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Divider(
                          height: 0,
                          color: appCtrl.appTheme.divider,
                          thickness: 1,
                        ),
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(appFonts.cancel.tr,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.manrope(
                                            color: appCtrl.appTheme.greyText,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14))
                                    .paddingSymmetric(vertical: Insets.i18)
                                    .inkWell(onTap: () async {
                                  Get.back();

                                  await getAdminPermission();
                                  isLoading = true;
                                  update();
                                  appCtrl.pref = pref;
                                  appCtrl.update();

                                  await appCtrl.storage
                                      .write(session.user, user);
                                  await appCtrl.storage
                                      .write(session.isIntro, true);
                                  Get.forceAppUpdate();

                                  await appCtrl.storage
                                      .write(session.isIntro, true);
                                  Get.forceAppUpdate();

                                  final FirebaseMessaging firebaseMessaging =
                                      FirebaseMessaging.instance;
                                  firebaseMessaging
                                      .getToken()
                                      .then((token) async {
                                    await FirebaseFirestore.instance
                                        .collection(collectionName.users)
                                        .doc(user["id"])
                                        .update({
                                      'status': "Online",
                                      "pushToken": token,
                                      "isActive": true,
                                      'phoneRaw': numberController.text,
                                      'phone':
                                          ((dialCode != null ? dialCode! : '') + numberController.text)
                                              .trim(),
                                      "dialCodePhoneList": phoneList(
                                          phone: numberController.text,
                                          dialCode: dialCode ?? '')
                                    });
                                    await Future.delayed(DurationsClass.s6);
                                    isLoading = false;
                                    update();

                                    Get.toNamed(routeName.dashboard,
                                        arguments: pref);
                                  });
                                }),
                              ),
                              VerticalDivider(
                                width: 1,
                                color: appCtrl.appTheme.divider,
                                thickness: 1,
                              ),
                              Expanded(
                                child: Text(appFonts.accept.tr,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.manrope(
                                          color: appCtrl.appTheme.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ))
                                    .paddingSymmetric(vertical: Insets.i18)
                                    .inkWell(onTap: () async {
                                  Get.back();
                                  await getAdminPermission();
                                  await appCtrl.storage
                                      .write(session.user, user);
                                  await appCtrl.storage
                                      .write(session.isIntro, true);
                                  Get.forceAppUpdate();

                                  final ContactProvider contactProvider =
                                      Provider.of<ContactProvider>(Get.context!,
                                          listen: false);
                                  bool isContact = await contactProvider
                                      .checkForLocalSaveOrNot();
                                  print('isContact :$isContact');
                                  if (isContact) {
                                    contactProvider.loadContactsFromLocal();
                                  } else {
                                    contactProvider.fetchContacts(
                                      appCtrl.user["phone"],
                                    );
                                  }

                                  final RecentChatController
                                      recentChatController =
                                      Provider.of<RecentChatController>(
                                          Get.context!,
                                          listen: false);
                                  if (pref != null) {
                                    recentChatController.checkChatList(pref!);
                                  }
                                  isLoading = true;
                                  update();
                                  appCtrl.pref = pref;
                                  appCtrl.update();

                                  await appCtrl.storage
                                      .write(session.isIntro, true);
                                  Get.forceAppUpdate();

                                  final FirebaseMessaging firebaseMessaging =
                                      FirebaseMessaging.instance;
                                  if (Platform.isAndroid) {
                                    firebaseMessaging
                                        .getToken()
                                        .then((token) async {
                                      await FirebaseFirestore.instance
                                          .collection(collectionName.users)
                                          .doc(user["id"])
                                          .update({
                                        'status': "Online",
                                        "pushToken": token,
                                        "isActive": true,
                                        'phoneRaw': numberController.text,
                                        'phone':
                                            ((dialCode != null ? dialCode! : '') + numberController.text)
                                                .trim(),
                                        "dialCodePhoneList": phoneList(
                                            phone: numberController.text,
                                            dialCode: dialCode ?? '')
                                      });
                                      await Future.delayed(DurationsClass.s6);
                                      isLoading = false;
                                      update();

                                      Get.toNamed(routeName.dashboard,
                                          arguments: pref);
                                    });
                                  } else {
                                    firebaseMessaging
                                        .getAPNSToken()
                                        .then((token) async {
                                      await FirebaseFirestore.instance
                                          .collection(collectionName.users)
                                          .doc(user["id"])
                                          .update({
                                        'status': "Online",
                                        "pushToken": token,
                                        "isActive": true,
                                        'phoneRaw': numberController.text,
                                        'phone':
                                            ((dialCode != null ? dialCode! : '') + numberController.text)
                                                .trim(),
                                        "dialCodePhoneList": phoneList(
                                            phone: numberController.text,
                                            dialCode: dialCode ?? '')
                                      });
                                      await Future.delayed(DurationsClass.s6);
                                      isLoading = false;
                                      update();

                                      Get.toNamed(routeName.dashboard,
                                          arguments: pref);
                                    });
                                  }
                                }),
                              ),
                            ],
                          ),
                        )
                      ],
                    ).width(MediaQuery.of(context).size.width)
                  ]));
        });
  }

  //navigate to dashboard
  homeNavigation(user) async {
    log("PREFF $user");
    contactPermissions(user);
  }

  // Helper function to create phone list for different dial code formats
  List<String> phoneList({required String phone, required String dialCode}) {
    List<String> phoneVariations = [];

    // Add the main phone number
    phoneVariations.add("$dialCode$phone");

    // Add variations without + sign
    if (dialCode.startsWith('+')) {
      phoneVariations.add("${dialCode.substring(1)}$phone");
    }

    // Add variation with + sign if not present
    if (!dialCode.startsWith('+')) {
      phoneVariations.add("+$dialCode$phone");
    }

    return phoneVariations;
  }

  final defaultPinTheme = PinTheme(
      textStyle: AppCss.manropeBold18.textColor(appCtrl.appTheme.greyText),
      width: Sizes.s55,
      height: Sizes.s48,
      decoration: BoxDecoration(
          color: appCtrl.appTheme.greyText.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppRadius.r8),
          border:
              Border.all(color: appCtrl.appTheme.greyText.withOpacity(0.15))));

  @override
  void onReady() async {
    pref = Get.arguments;
    log("LOG PREF READY $pref");

    try {
      final usageControls = await FirebaseFirestore.instance
          .collection(collectionName.config)
          .doc(collectionName.usageControls)
          .get();
      log("USAGE CONTROL ${usageControls.data()!}");

      // Check demo mode on startup
      if (usageControls.exists && usageControls.data() != null) {
        isDemoMode = usageControls.data()!['demoMode'] ?? false;
        log("Initial demo mode status: $isDemoMode");
      }

      appCtrl.usageControlsVal =
          UsageControlModel.fromJson(usageControls.data()!);

      appCtrl.storage.write(session.usageControls, usageControls.data());

      final userAppSettings = await FirebaseFirestore.instance
          .collection(collectionName.config)
          .doc(collectionName.userAppSettings)
          .get();
      log("admin 4: ${userAppSettings.data()}");
      log("USAGE CONTROL ${appCtrl.userAppSettingsVal?.firebaseServerToken}");
      appCtrl.userAppSettingsVal =
          UserAppSettingModel.fromJson(userAppSettings.data()!);

      final String systemLocales =
          WidgetsBinding.instance.platformDispatcher.locale.countryCode!;
      List country = countriesEnglish;
      int index =
          country.indexWhere((element) => element['code'] == systemLocales);
      if (index >= 0) {
        dialCode = country[index]['dial_code'];
      }
    } catch (e) {
      log("Error in onReady: $e");
    }

    update();
    log("DIAL : $dialCode");
    super.onReady();
  }
}
