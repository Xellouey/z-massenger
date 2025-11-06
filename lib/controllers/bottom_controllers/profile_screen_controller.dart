import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_luban/flutter_luban.dart';
import '../../config.dart';
import '../../models/status_model.dart';
import '../../utils/snack_and_dialogs_utils.dart';
import '../../widgets/reaction_pop_up/emoji_picker_widget.dart';

class ProfileScreenController extends GetxController {
  TextEditingController emailController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  GlobalKey<FormState> profileGlobalKey = GlobalKey<FormState>();

  bool isLoading = false;
  String imageUrl = "";
  XFile? imageFile;
  String? image;

  onTapEmoji() {
    showModalBottomSheet(
        barrierColor: appCtrl.appTheme.trans,
        backgroundColor: appCtrl.appTheme.trans,
        context: Get.context!,
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.r25))),
        builder: (BuildContext context) {
          // return your layout
          return EmojiPickerWidget(
              controller: statusController,
              onSelected: (emoji) {
                statusController.text + emoji;
              });
        });
    update();
  }

  updateUserData() async {
    if (profileGlobalKey.currentState!.validate()) {

      log("imageUrl : $imageUrl");
      update();

      final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
      String? token = await firebaseMessaging.getToken();

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(appCtrl.user["id"])
          .get();

      if (!userDoc.exists) {
        log("User does not exist");
        isLoading = false;
        update();
        return;
      }

      var currentUserData = userDoc.data() as Map<String, dynamic>;
      var newUserData = {
        'image': imageUrl.isNotEmpty ? imageUrl : appCtrl.user["image"],
        'name': userNameController.text,
        'status': "Online",
        'typeStatus': "",
        'email': emailController.text,
        'statusDesc': statusController.text,
        'pushToken': token,
        'isActive': true
      };

      // Compare new data with current data
      bool isDataChanged = false;
      newUserData.forEach((key, value) {
        if (currentUserData[key] != value) {
          isDataChanged = true;
        }
      });

      if (isDataChanged) {
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(appCtrl.user["id"])
            .update(newUserData)
            .then((result) async {
          log("User updated successfully");

          DocumentSnapshot updatedUserDoc = await FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(appCtrl.user["id"])
              .get();

          appCtrl.user = updatedUserDoc.data();
          appCtrl.update();
          await appCtrl.storage.write(session.id, appCtrl.user["id"]);
          await appCtrl.storage.write(session.user, updatedUserDoc.data());

          flutterAlertMessage(
              msg: appFonts.dataUpdatingSuccessfully.tr,
              bgColor: appCtrl.appTheme.primary);
        }).catchError((onError) {
          log("Error updating user: $onError");
        });
      }
      isLoading = false;
      update();
    }
  }

/*  Future getImage(source) async {
    final ImagePicker picker = ImagePicker();
    XFile? compressedFiles = (await picker.pickImage(source: source))!;
    final tempDir = await getTemporaryDirectory();
    CompressObject compressObject = CompressObject(
      imageFile: File(compressedFiles.path),
      //image
      path: tempDir.path,
      //compress to path
      quality: 100,
      //first compress quality, default 80
      step: 9,
      mode: CompressMode.AUTO, //default AUTO
    );
    Luban.compressImage(compressObject).then((imagePath) {
      imageFile = XFile(imagePath!);
      File images = File(imageFile!.path);
      log("PATH :$image");
      if (images.lengthSync() / 1000000 >
          appCtrl.usageControlsVal!.maxFileSize!) {
        imageFile = null;

        snackBar(
            "Image Should be less than ${images.lengthSync() / 1000000 > appCtrl.usageControlsVal!.maxFileSize!}");
      } else {
        if (imageFile != null) {
          update();
          uploadFile();
        }
      }
    });
    update();
  }*/
// GET IMAGE FROM GALLERY
  Future getImage(source) async {
    final ImagePicker picker = ImagePicker();
    XFile? compressedFiles = (await picker.pickImage(source: source))!;
    final tempDir = await getTemporaryDirectory();
    CompressObject compressObject = CompressObject(
      imageFile: File(compressedFiles.path),
      //image
      targetPath: tempDir.path,
      //compress to path
      quality: 100,
      //first compress quality, default 80
      step: 9,
      mode: CompressMode.AUTO, //default AUTO
    );
    Luban.compressImage(compressObject).then((imagePath) {
      imageFile = XFile(imagePath!);
      File images = File(imageFile!.path);
      log("PATH :$image");
      if (images.lengthSync() / 1000000 >
          appCtrl.usageControlsVal!.maxFileSize!) {
        imageFile = null;

        snackBar(
            "Image Should be less than ${images.lengthSync() / 1000000 > appCtrl.usageControlsVal!.maxFileSize!}");
      } else {
        if (imageFile != null) {
          update();
          uploadFile();
        }
      }
    });
    update();
  }

  logout() async {
    var user = appCtrl.storage.read(session.user);
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(user["id"])
        .update({
      "status": "Offline",
      "lastSeen": DateTime.now().millisecondsSinceEpoch.toString()
    });
    update();
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

    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.remove(session.chatList);
    preferences.remove(session.registerUser);
    preferences.remove(session.unRegisterUser);
    preferences.remove(session.statusList);
    preferences.clear();

    Get.offAllNamed(routeName.phoneWrap);
    appCtrl.update();
    update();
  }

// UPLOAD SELECTED IMAGE TO FIREBASE
  Future uploadFile() async {
    isLoading = true;
    update();
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref().child(fileName);
    log("reference : $reference");
    var file = File(imageFile!.path);
    UploadTask uploadTask = reference.putFile(file);

    uploadTask.then((res) {
      log("res : $res");
      res.ref.getDownloadURL().then((downloadUrl) async {
        image = imageUrl;
        await appCtrl.storage.write(session.user, appCtrl.user);
        imageUrl = downloadUrl;
        log(appCtrl.user["id"]);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(appCtrl.user["id"])
            .update({'image': imageUrl}).then((value) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(appCtrl.user["id"])
              .get()
              .then((snap) async {
            await appCtrl.storage.write(session.user, snap.data());
            appCtrl.user = snap.data();
            final dashCtrl = Get.isRegistered<DashboardController>()
                ? Get.find<DashboardController>()
                : Get.put(DashboardController());
            dashCtrl.data = imageUrl;
            dashCtrl.update();
            update();
          });
        });
        isLoading = false;
        update();
        log("IMAGE $image");

        update();
      }, onError: (err) {
        update();
        Fluttertoast.showToast(msg: 'Image is Not Valid');
      });
    });
  }

  void onTapProfile(String imageUrl) {
    showDialog(
      context: Get.context!,
      builder: (context) {
        final theme = appCtrl.appTheme;
        final textStyle = AppCss.manropeBold14.textColor(theme.darkText);

        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r8),
          ),
          backgroundColor: theme.white,
          titlePadding: const EdgeInsets.all(Insets.i20),
          title: Column(
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        appFonts.addProfile.tr,
                        style: AppCss.manropeBold16.textColor(theme.darkText)
                    ),
                    Icon(CupertinoIcons.multiply, color: theme.darkText).inkWell(
                      onTap: () => Get.back(),
                    )
                  ]
              ),
              const VSpace(Sizes.s15),
              Divider(
                color: theme.darkText.withOpacity(0.1),
                height: 1,
                thickness: 1,
              )
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Image.asset(eImageAssets.gallery, height: Sizes.s44),
                const HSpace(Sizes.s15),
                Text(appFonts.selectFromGallery.tr,
                    style:textStyle /*AppCss.manropeBold14
                        .textColor(appCtrl.appTheme.darkText)*/)
              ]).inkWell(onTap: () {
                getImage(ImageSource.gallery);
                Get.back();
              }).paddingOnly(bottom: Insets.i30),
              Row(children: [
                Image.asset(eImageAssets.camera, height: Sizes.s44),
                const HSpace(Sizes.s15),
                Text(appFonts.openCamera.tr,
                    style: AppCss.manropeBold14
                        .textColor(appCtrl.appTheme.darkText))
              ]).inkWell(onTap: () {
                getImage(ImageSource.camera);
                Get.back();
              }).paddingOnly(bottom: Insets.i30),
              if (imageUrl != '')
                Row(children: [
                  Image.asset(eImageAssets.anonymous, height: Sizes.s44),
                  const HSpace(Sizes.s15),
                  Text(appFonts.removePhoto,
                      style: AppCss.manropeBold14
                          .textColor(appCtrl.appTheme.darkText))
                ]).inkWell(onTap: () {
                  Get.back();
                  noProfile();
                  update();
                })

            ],
          ).padding(horizontal: Sizes.s20, bottom: Insets.i20),
        );
      },
    );
  }

/*
  onTapProfile(profileCtrl) {
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
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(appFonts.addProfile.tr,
                          style: AppCss.manropeBold16
                              .textColor(appCtrl.appTheme.darkText)),
                      Icon(CupertinoIcons.multiply,
                          color: appCtrl.appTheme.darkText)
                          .inkWell(onTap: () => Get.back())
                    ]),
                const VSpace(Sizes.s15),
                Divider(
                    color: appCtrl.appTheme.darkText.withOpacity(0.1),
                    height: 1,
                    thickness: 1)
              ]),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Image.asset(eImageAssets.gallery, height: Sizes.s44),
                  const HSpace(Sizes.s15),
                  Text(appFonts.selectFromGallery.tr,
                      style: AppCss.manropeBold14
                          .textColor(appCtrl.appTheme.darkText))
                ]).inkWell(onTap: () {
                  getImage(ImageSource.gallery);
                  Get.back();
                }).paddingOnly(bottom: Insets.i30),
                Row(children: [
                  Image.asset(eImageAssets.camera, height: Sizes.s44),
                  const HSpace(Sizes.s15),
                  Text(appFonts.openCamera.tr,
                      style: AppCss.manropeBold14
                          .textColor(appCtrl.appTheme.darkText))
                ]).inkWell(onTap: () {
                  getImage(ImageSource.camera);
                  Get.back();
                }).paddingOnly(bottom: Insets.i30),
                if (profileCtrl != '')
                  Row(children: [
                    Image.asset(eImageAssets.anonymous, height: Sizes.s44),
                    const HSpace(Sizes.s15),
                    Text(appFonts.removePhoto,
                        style: AppCss.manropeBold14
                            .textColor(appCtrl.appTheme.darkText))
                  ]).inkWell(onTap: () {
                    Get.back();
                    noProfile();
                    update();
                  })
              ]).padding(horizontal: Sizes.s20, bottom: Insets.i20));
        });
  }*/

  noProfile() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(appCtrl.user["id"])
        .update({'image': ""}).then((value) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(appCtrl.user["id"])
          .get()
          .then((snap) async {
        await appCtrl.storage.write(session.user, snap.data());
        appCtrl.user = snap.data();
        final dashCtrl = Get.isRegistered<DashboardController>()
            ? Get.find<DashboardController>()
            : Get.put(DashboardController());
        dashCtrl.data = "";
        dashCtrl.update();
        imageUrl = '';
        update();
      });
    });
  }

  deleteUser() async {
    await showDialog(
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
                Image.asset(eImageAssets.deleteAccount,
                    height: Sizes.s115, width: Sizes.s115),
                Text(appFonts.deleteAccount.tr,
                    style: AppCss.manropeBold16
                        .textColor(appCtrl.appTheme.darkText)),
                const VSpace(Sizes.s10),
                Text(appFonts.youWillLostAllData.tr,
                    textAlign: TextAlign.center,
                    style: AppCss.manropeMedium14
                        .textColor(appCtrl.appTheme.greyText)),
                Divider(
                    height: 1,
                    color: appCtrl.appTheme.borderColor,
                    thickness: 1)
                    .paddingSymmetric(vertical: Insets.i15),
                Text(appFonts.deleteAccount.tr,
                    style: AppCss.manropeblack14
                        .textColor(appCtrl.appTheme.redColor))
                    .inkWell(onTap: () async {
                  isLoading = true;
                  update();

                  await FirebaseFirestore.instance
                      .collection(collectionName.calls)
                      .doc(appCtrl.user["id"])
                      .delete();
                  await FirebaseFirestore.instance
                      .collection(collectionName.users)
                      .doc(appCtrl.user["id"])
                      .collection(collectionName.status)
                      .get()
                      .then((value) {
                    for (QueryDocumentSnapshot<Map<String, dynamic>> ds
                    in value.docs) {
                      Status status = Status.fromJson(ds.data());
                      List<PhotoUrl> photoUrl = status.photoUrl ?? [];
                      for (var list in photoUrl) {
                        if (list.statusType == StatusType.image.name ||
                            list.statusType == StatusType.video.name) {
                          FirebaseStorage.instance
                              .refFromURL(list.image!)
                              .delete();
                        }
                      }
                    }
                  });
                  await FirebaseFirestore.instance
                      .collection(collectionName.users)
                      .doc(appCtrl.user["id"])
                      .collection(collectionName.chats)
                      .get()
                      .then((value) {
                    for (DocumentSnapshot ds in value.docs) {
                      ds.reference.delete();
                    }
                  });
                  await FirebaseFirestore.instance
                      .collection(collectionName.users)
                      .doc(appCtrl.user["id"])
                      .collection(collectionName.messages)
                      .get()
                      .then((value) {
                    for (QueryDocumentSnapshot<Map<String, dynamic>> ds
                    in value.docs) {
                      if (ds.data()["type"] == MessageType.image.name ||
                          ds.data()["type"] == MessageType.audio.name ||
                          ds.data()["type"] == MessageType.video.name ||
                          ds.data()["type"] == MessageType.doc.name ||
                          ds.data()["type"] == MessageType.gif.name ||
                          ds.data()["type"] == MessageType.imageArray.name) {
                        String url = decryptMessage(ds.data()["content"]);
                        FirebaseStorage.instance
                            .refFromURL(url.contains("-BREAK-")
                            ? url.split("-BREAK-")[0]
                            : url)
                            .delete();
                      }
                      ds.reference.delete();
                    }
                  });
                  await FirebaseFirestore.instance
                      .collection(collectionName.users)
                      .doc(appCtrl.user["id"])
                      .collection(collectionName.groupMessage)
                      .get()
                      .then((value) {
                    for (QueryDocumentSnapshot<Map<String, dynamic>> ds
                    in value.docs) {
                      if (ds.data()["type"] == MessageType.image.name ||
                          ds.data()["type"] == MessageType.audio.name ||
                          ds.data()["type"] == MessageType.video.name ||
                          ds.data()["type"] == MessageType.doc.name ||
                          ds.data()["type"] == MessageType.gif.name ||
                          ds.data()["type"] == MessageType.imageArray.name) {
                        String url = decryptMessage(ds.data()["content"]);
                        FirebaseStorage.instance
                            .refFromURL(url.contains("-BREAK-")
                            ? url.split("-BREAK-")[0]
                            : url)
                            .delete();
                      }
                      ds.reference.delete();
                    }
                  });

                  await FirebaseFirestore.instance
                      .collection(collectionName.users)
                      .doc(appCtrl.user["id"])
                      .collection(collectionName.broadcastMessage)
                      .get()
                      .then((value) {
                    for (QueryDocumentSnapshot<Map<String, dynamic>> ds
                    in value.docs) {
                      if (ds.data()["type"] == MessageType.image.name ||
                          ds.data()["type"] == MessageType.audio.name ||
                          ds.data()["type"] == MessageType.video.name ||
                          ds.data()["type"] == MessageType.doc.name ||
                          ds.data()["type"] == MessageType.gif.name ||
                          ds.data()["type"] == MessageType.imageArray.name) {
                        String url = decryptMessage(ds.data()["content"]);
                        FirebaseStorage.instance
                            .refFromURL(url.contains("-BREAK-")
                            ? url.split("-BREAK-")[0]
                            : url)
                            .delete();
                      }
                      ds.reference.delete();
                    }
                  });

                  await FirebaseFirestore.instance
                      .collection(collectionName.users)
                      .doc(appCtrl.user["id"])
                      .delete();
                  await appCtrl.storage.remove(session.isDarkMode);
                  await appCtrl.storage.remove(session.isRTL);
                  await appCtrl.storage.remove(session.languageCode);
                  await appCtrl.storage.remove(session.languageCode);
                  await appCtrl.storage.remove(session.user);
                  await appCtrl.storage.remove(session.id);
                  FirebaseAuth.instance.signOut();

                  SharedPreferences preferences =
                  await SharedPreferences.getInstance();
                  preferences.remove(session.chatList);
                  preferences.remove(session.registerUser);
                  preferences.remove(session.unRegisterUser);
                  preferences.remove(session.statusList);
                  preferences.clear();
                  isLoading = false;
                  update();
                  appCtrl.pref!.remove('storageUserString');
                  appCtrl.user = null;
                  appCtrl.pref = null;

                  Get.offAllNamed(routeName.phoneWrap, arguments: appCtrl.pref);
                })
              ]).padding(horizontal: Sizes.s20, bottom: Insets.i20));
        });
  }

  @override
  void onReady() {
    emailController.text = appCtrl.user["email"] ?? '';
    statusController.text = appCtrl.user["statusDesc"] ?? '';
    userNameController.text = appCtrl.user["name"] ?? '';
    numberController.text = appCtrl.user["phone"] ?? '';
    update();

    // TODO: implement onReady
    super.onReady();
  }
}
