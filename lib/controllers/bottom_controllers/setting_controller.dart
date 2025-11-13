import 'dart:developer';
import 'dart:io';

import 'package:chatzy/config.dart';
import 'package:chatzy/controllers/bottom_controllers/profile_screen_controller.dart';
import 'package:chatzy/controllers/common_controllers/contact_controller.dart';
import 'package:chatzy/controllers/common_controllers/contact_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:localstorage/localstorage.dart';

class SettingController extends GetxController {
  List settingLists = [];

  @override
  void onReady() {
    log('Setting Controller onReady - appArray: ${appArray}');
    settingLists = appArray.settingList;
    log('Setting Controller - settingLists length: ${settingLists.length}');
    log('Setting Controller - settingLists: ${settingLists}');
    update();
    // TODO: implement onReady
    super.onReady();
  }

  /// this will delete cache
  Future<void> deleteCacheDir() async {
    Directory tempDir = await getTemporaryDirectory();
    log("tempDir.existsSync(): ${tempDir.existsSync()}");
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }

    update();
    Get.forceAppUpdate();
  }

  /// this will delete app's storage
  Future<void> deleteAppDir() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    log("tempDir.existsSync()1: ${appDocDir.existsSync()}");
    if (appDocDir.existsSync()) {
      appDocDir.deleteSync(recursive: true);
    }
    update();
    Get.forceAppUpdate();
  }

  cacheDialog() {
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
                  Icon(CupertinoIcons.multiply,
                          color: appCtrl.appTheme.darkText)
                      .inkWell(onTap: () => Get.back())
                ])
              ]),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Image.asset(eImageAssets.successTick,
                    height: Sizes.s115, width: Sizes.s115),
                const VSpace(Sizes.s20),
                Text(appFonts.successfullyCacheClear.tr,
                    style: AppCss.manropeBold16
                        .textColor(appCtrl.appTheme.darkText)),
                const VSpace(Sizes.s10),
                Text(appFonts.reOpenApp.tr,
                    textAlign: TextAlign.center,
                    style: AppCss.manropeMedium14
                        .textColor(appCtrl.appTheme.greyText)),
                const VSpace(Sizes.s15),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Divider(
                        height: 1,
                        color: appCtrl.appTheme.borderColor,
                        thickness: 1),
                    const VSpace(Sizes.s15),
                    Text(appFonts.reOpen.tr,
                            style: AppCss.manropeblack14
                                .textColor(appCtrl.appTheme.primary))
                        .inkWell(onTap: () {
                      Get.back();
                      exit(0);
                    })
                  ],
                ).width(MediaQuery.of(context).size.width).inkWell(onTap: () {
                  Get.back();
                  exit(0);
                })
              ]).padding(horizontal: Sizes.s20, bottom: Insets.i20));
        });
  }

  onSettingTap(data) async {
    if (data['title'] == appFonts.appLanguage) {
      Get.toNamed(routeName.languageScreen);
    } else if (data['title'] == appFonts.syncNow) {
      final ContactProvider contactCtrl =
          Provider.of<ContactProvider>(Get.context!, listen: false);

      syncContactAlert(contactCtrl.registeredContacts.length);
    } else if (data['title'] == appFonts.rateApp) {
   /*   LaunchReview.launch(
          androidAppId: appCtrl.userAppSettingsVal!.rateApp,
          iOSAppId: " ${appCtrl.userAppSettingsVal!.rateAppIos}");*/
    } else if (data['title'] == appFonts.logOut) {
      var user = appCtrl.storage.read(session.user);
      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(appCtrl.user["id"])
          .update({
        "status": "Offline",
        "lastSeen": DateTime.now().millisecondsSinceEpoch.toString()
      });
      FirebaseAuth.instance.signOut();
      await appCtrl.storage.remove(session.user);
      await appCtrl.storage.remove(session.id);
      await appCtrl.storage.remove(session.contactPermission);
      await appCtrl.storage.remove(session.isDarkMode);
      await appCtrl.storage.remove(session.isRTL);
      await appCtrl.storage.remove(session.languageCode);
      appCtrl.pref!.remove('storageUserString');
      appCtrl.user = null;
      appCtrl.pref = null;


      Get.offAllNamed(routeName.phoneWrap);
      appCtrl.update();
    } else if (data['title'] == appFonts.clearStorage) {
      await deleteAppDir();
      await deleteCacheDir();
      cacheDialog();
    } else if (data['title'] == appFonts.deleteAccount) {
      final profileCtrl = Get.isRegistered<ProfileScreenController>()
          ? Get.find<ProfileScreenController>()
          : Get.put(ProfileScreenController());
      await profileCtrl.deleteUser();
    }
  }

  syncContactAlert(len) {
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
                    Text(appFonts.youContactSync(len.toString()),
                            style: GoogleFonts.manrope(
                                color: appCtrl.appTheme.darkText,
                                fontWeight: FontWeight.w600,
                                fontSize: 16))
                        .marginSymmetric(horizontal: Insets.i12),
                    const VSpace(Sizes.s12),
                    Text(appFonts.endToEndEncryption.tr,
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
                        ButtonCommon(
                            margin: Insets.i20,
                            boxShadow: [
                              BoxShadow(
                                  color: appCtrl.appTheme.primary
                                      .withOpacity(0.40),
                                  offset: const Offset(0, 2),
                                  blurRadius: AppRadius.r5,
                                  spreadRadius: AppRadius.r2)
                            ],
                            title: appFonts.syncNow.tr,
                            style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: appCtrl.appTheme.sameWhite),
                            onTap: () {
                              final ContactProvider contactCtrl =
                                  Provider.of<ContactProvider>(
                                      Get.context!,
                                      listen: false);
                              FirebaseFirestore.instance
                                  .collection(collectionName.users)
                                  .doc(FirebaseAuth.instance.currentUser != null
                                      ? FirebaseAuth.instance.currentUser!.uid
                                      : appCtrl.user["id"])
                                  .collection(collectionName.userContact)
                                  .get()
                                  .then((value) async {
                                if (value.docs.isEmpty) {
                                  FirebaseFirestore.instance
                                      .collection(collectionName.users)
                                      .doc(FirebaseAuth.instance.currentUser !=
                                              null
                                          ? FirebaseAuth
                                              .instance.currentUser!.uid
                                          : appCtrl.user["id"])
                                      .collection(collectionName.userContact)
                                      .add({
                                    'contacts': RegisterContactDetail.encode(
                                        contactCtrl.registeredContacts)
                                  });
                                } else {
                                  if (value.docs.length > 1) {
                                    value.docs
                                        .asMap()
                                        .entries
                                        .forEach((element) {
                                      element.value.reference.delete();
                                    });
                                    FirebaseFirestore.instance
                                        .collection(collectionName.users)
                                        .doc(
                                            FirebaseAuth.instance.currentUser !=
                                                    null
                                                ? FirebaseAuth
                                                    .instance.currentUser!.uid
                                                : appCtrl.user["id"])
                                        .collection(collectionName.userContact)
                                        .add({
                                      'contacts': RegisterContactDetail.encode(
                                          contactCtrl.registeredContacts)
                                    });
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection(collectionName.users)
                                        .doc(appCtrl.user["id"])
                                        .collection(collectionName.userContact)
                                        .doc(value.docs[0].id)
                                        .update({
                                      'contacts': RegisterContactDetail.encode(
                                          contactCtrl.registeredContacts)
                                    });
                                  }
                                  FirebaseFirestore.instance
                                      .collection(collectionName.users)
                                      .doc(FirebaseAuth.instance.currentUser !=
                                              null
                                          ? FirebaseAuth
                                              .instance.currentUser!.uid
                                          : appCtrl.user["id"])
                                      .update({'isWebLogin': false});
                                }
                              });
                              Get.back();
                              Get.snackbar("${appFonts.success.tr}!",
                                  appFonts.contactSync.tr,
                                  backgroundColor: appCtrl.appTheme.primary,
                                  colorText: appCtrl.appTheme.white);
                            }),
                        const VSpace(Sizes.s30),
                        Text(appFonts.deleteSyncContact.tr,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                    color: appCtrl.appTheme.redColor,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14))
                            .marginSymmetric(horizontal: Insets.i12)
                            .inkWell(onTap: () async {
                          FirebaseFirestore.instance
                              .collection(collectionName.users)
                              .doc(FirebaseAuth.instance.currentUser != null
                                  ? FirebaseAuth.instance.currentUser!.uid
                                  : appCtrl.user["id"])
                              .collection(collectionName.userContact)
                              .get()
                              .then((value) async {
                            if (value.docs.isNotEmpty) {
                              value.docs.asMap().entries.forEach((element) {
                                element.value.reference.delete();
                              });
                            }
                          });
                          Get.back();
                          Get.snackbar("${appFonts.delete.tr}!",
                              appFonts.deleteSyncContact.tr,
                              backgroundColor: appCtrl.appTheme.primary,
                              colorText: appCtrl.appTheme.white);
                        }),
                        const VSpace(Sizes.s35),
                      ],
                    ).width(MediaQuery.of(context).size.width)
                  ]));
        });
  }

  onChange(value, data) async {
    if (data["title"] == appFonts.theme) {
      appCtrl.storage.write(session.isDarkMode, appCtrl.isTheme);
      appCtrl.isTheme = value;
      appCtrl.update();
      ThemeService().switchTheme(appCtrl.isTheme);
      Get.forceAppUpdate();
    } else {
      final fingerCtrl = Get.isRegistered<AddFingerprintController>()
          ? Get.find<AddFingerprintController>()
          : Get.put(AddFingerprintController());
      log("appCtrl.isBiometric :${appCtrl.isBiometric}");
      if (!appCtrl.isBiometric) {
        fingerCtrl.authenticate(isDialog: true);
        fingerCtrl.onInit();
        log("appCtrl.isBiometric:${appCtrl.isBiometric}");
        Get.toNamed(routeName.fingerScannerScreen);

        appCtrl.update();
      } else {
        await fingerCtrl.auth
            .authenticate(
                localizedReason: "Scan your finger to authenticate",
                options: const AuthenticationOptions(
                    useErrorDialogs: false, stickyAuth: false))
            .then((_) {
          log("hvnghj");
          appCtrl.isBiometric = false;

          appCtrl.storage.write(session.isBiometric, false);
          appCtrl.update();
          Get.forceAppUpdate();
        });
        // fingerCtrl.authenticate(isDialog: false);
      }
    }
    appCtrl.update();
  }
}
