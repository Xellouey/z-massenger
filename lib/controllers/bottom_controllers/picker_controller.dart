import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_luban/flutter_luban.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:light_compressor/light_compressor.dart' as light;
import 'package:video_compress/video_compress.dart';

import '../../config.dart';
import '../../screens/app_screens/chat_message/layouts/image_picker.dart';
import '../../utils/snack_and_dialogs_utils.dart';

class PickerController extends GetxController {
  XFile? imageFile;
  XFile? videoFile;
  File? image;
  File? video;
  String? imageUrl;
  String? audioUrl;
  List<File> selectedImages = [];

// GET IMAGE FROM GALLERY
  Future getImage(source) async {
    final ImagePicker picker = ImagePicker();
    imageFile = (await picker.pickImage(source: source, imageQuality: 30))!;
    if (imageFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile!.path,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: appCtrl.appTheme.primary,
              toolbarWidgetColor: appCtrl.appTheme.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
        ],
      );
      final tempDir = await getTemporaryDirectory();
      if (croppedFile != null) {
        CompressObject compressObject = CompressObject(
          imageFile: File(croppedFile.path),
          //image
          targetPath: tempDir.path,
          //compress to path
          quality: 80,
          //first compress quality, default 80
          step: 9,
          mode: CompressMode.AUTO, //default AUTO
        );
        // Luban.compressImage(compressObject).then((imagePath) {
        //   image = File(imagePath!);
        //   log("PATH :$image");
        //   if (image!.lengthSync() / 1000000 >
        //       appCtrl.usageControlsVal!.maxFileSize!) {
        //     image = null;
        //     snackBar(
        //         "Image Should be less than ${image!.lengthSync() / 1000000 > appCtrl.usageControlsVal!.maxFileSize!}");
        //   }
        image = File(compressObject.imageFile!.path);
        // });
      }

      log("image1 : $image");
      // log("image1 : ${image!.lengthSync() / 1000000 > 60}");

      Get.forceAppUpdate();
    }
  }

// GET IMAGE FROM GALLERY
  Future getMultipleImage({isImage = true}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: [
        'jpg',
        'png',
        'jpeg',
      ],
    );

    debugPrint("resultresult: $result");
    if (result != null) {
      for (var i = 0; i < result.files.length; i++) {
        selectedImages.add(File(result.files[i].path!));
      }
      return selectedImages;
    } else {
      // If no image is selected it will show a
      // snackbar saying nothing is selected
      ScaffoldMessenger.of(Get.context!)
          .showSnackBar(const SnackBar(content: Text('Nothing is selected')));
    }
  }

// GET VIDEO FROM GALLERY
  Future getMultipleVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: ['mp4'],
    );

    log("resultresult: $result");
    if (result != null) {
      for (var i = 0; i < result.files.length; i++) {
        selectedImages.add(File(result.files[i].path!));
      }
      return selectedImages;
    } else {
      // If no image is selected it will show a
      // snackbar saying nothing is selected
      ScaffoldMessenger.of(Get.context!)
          .showSnackBar(const SnackBar(content: Text('Nothing is selected')));
    }
  }

// FOR Dismiss KEYBOARD
  void dismissKeyboard() {
    FocusScope.of(Get.context!).requestFocus(FocusNode());
  }

  // image picker option
  imagePickerOption(BuildContext context,
      {isGroup = false, isSingleChat = false, isCreateGroup = false})
  {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.r25)),
        ),
        builder: (BuildContext context) {
          // return your layout
          return ImagePickerLayout(cameraTap: () async {
            dismissKeyboard();

            await getImage(ImageSource.camera).then((value) async {
              log("VALUE : $value");
              if (isGroup) {
                final chatCtrl = Get.find<GroupChatMessageController>();
                chatCtrl.uploadFile();
              } else if (isSingleChat) {
                final singleChatCtrl = Get.find<ChatController>();
                singleChatCtrl.uploadFile();
              } else if (isCreateGroup) {
                final singleChatCtrl = Get.find<GroupMessageController>();
                singleChatCtrl.uploadFile();
              } else {
                final broadcastCtrl = Get.find<BroadcastChatController>();
                broadcastCtrl.uploadFile();
              }
            });
            Get.back();
          }, galleryTap: () async {
            debugPrint("cameraPermission : ");
            PermissionStatus cameraPermission =
            await Permission.camera.request();
            debugPrint("cameraPermission : $cameraPermission");
            if (isCreateGroup) {
              getImage(ImageSource.gallery).then((value) {
                final singleChatCtrl = Get.find<GroupMessageController>();
                singleChatCtrl.uploadFile();
              });
            } else {
              await getMultipleImage().then((value) async {
                final tempDir = await getTemporaryDirectory();
                if (value != null) {
                  if (isGroup) {
                    debugPrint("isGroup::${isGroup}");
                    final chatCtrl = Get.find<GroupChatMessageController>();
                    chatCtrl.selectedImages = value;
                    chatCtrl.isLoading = true;
                    chatCtrl.update();
                    chatCtrl.selectedImages
                        .asMap()
                        .entries
                        .forEach((element) async {
                      File? videoFile = element.value;
                      try {
                        if (element.value.name.contains("mp4")) {
                          final light.LightCompressor lightCompressor =
                          light.LightCompressor();
                          final dynamic response =
                          await lightCompressor.compressVideo(
                            path: videoFile.path,
                            videoQuality: light.VideoQuality.very_low,
                            isMinBitrateCheckEnabled: false,
                            video: light.Video(videoName: element.value.name),
                            android: light.AndroidConfig(
                                isSharedStorage: true,
                                saveAt: light.SaveAt.Movies),
                            ios: light.IOSConfig(saveInGallery: false),
                          );

                          video = File(videoFile.path);
                          if (response is light.OnSuccess) {
                            log("videoFile!.path 1: ${getVideoSize(file: File(response.destinationPath))}}");
                            video = File(response.destinationPath);
                            chatCtrl
                                .uploadMultipleFile(video!, MessageType.video)
                                .then((value) {
                              video = null;
                              videoFile = null;
                              update();
                            });
                          } else {
                            chatCtrl.isLoading = false;
                            chatCtrl.update();
                            video = null;
                            videoFile = null;
                            update();
                          }
                        } else {
                          log("image!.path::${videoFile.path}");
                          CompressObject compressObject = CompressObject(
                            imageFile: File(videoFile.path),
                            //image
                            targetPath: tempDir.path,
                            //compress to path
                            quality: 80,
                            //first compress quality, default 80
                            step: 9,
                            mode: CompressMode.AUTO, //default AUTO
                          );
                          Luban.compressImage(compressObject).then((imagePath) async {
                            image = File(imagePath!);
                            if (image!.lengthSync() / 1000000 >
                                appCtrl.usageControlsVal!.maxFileSize!) {
                              image = null;
                              snackBar(
                                  "Image Should be less than ${image!.lengthSync() / 1000000 > appCtrl.usageControlsVal!.maxFileSize!}");
                              chatCtrl.isLoading = false;
                              chatCtrl.update();
                            } else {

                              chatCtrl
                                  .uploadMultipleFile(videoFile!, MessageType.image)
                                  .then((value) {
                                image = null;
                                videoFile = null;
                                update();
                              });
                            }
                            update();
                          });

                          image = File(videoFile!.path);
                          log("message::$image");
                          update();
                          chatCtrl.update();
                        }
                      } catch (e) {
                        chatCtrl.isLoading = false;
                        chatCtrl.update();
                      }
                    });
                    selectedImages = [];
                    update();
                  } else if (isSingleChat) {
                    final singleChatCtrl = Get.find<ChatController>();
                    singleChatCtrl.selectedImages = value;
                    singleChatCtrl.selectedImages
                        .asMap()
                        .entries
                        .forEach((element) async {
                      File? videoFile = element.value;
                      singleChatCtrl.isLoading = true;
                      singleChatCtrl.update();
                      try {
                        if (element.value.name.contains("mp4")) {
                          final light.LightCompressor lightCompressor =
                          light.LightCompressor();
                          final dynamic response =
                          await lightCompressor.compressVideo(
                            path: videoFile.path,
                            videoQuality: light.VideoQuality.very_low,
                            isMinBitrateCheckEnabled: false,
                            video: light.Video(videoName: element.value.name),
                            android: light.AndroidConfig(
                                isSharedStorage: true,
                                saveAt: light.SaveAt.Movies),
                            ios: light.IOSConfig(saveInGallery: false),
                          );

                          video = File(videoFile.path);
                          if (response is light.OnSuccess) {
                            log("videoFile!.path 1: ${getVideoSize(file: File(response.destinationPath))}}");
                            video = File(response.destinationPath);
                            singleChatCtrl
                                .uploadMultipleFile(video!, MessageType.video)
                                .then((value) {
                              video = null;
                              videoFile = null;
                              update();
                            });
                          } else {
                            singleChatCtrl.isLoading = false;
                            singleChatCtrl.update();
                            video = null;
                            videoFile = null;
                            update();
                          }
                        } else {
                          CompressObject compressObject = CompressObject(
                            imageFile: File(videoFile.path),
                            //image
                            targetPath: tempDir.path,
                            //compress to path
                            quality: 80,
                            //first compress quality, default 80
                            step: 9,
                            mode: CompressMode.AUTO, //default AUTO
                          );
                          Luban.compressImage(compressObject).then((imagePath) async {
                            image = File(imagePath!);
                            if (image!.lengthSync() / 1000000 >
                                appCtrl.usageControlsVal!.maxFileSize!) {
                              image = null;
                              snackBar(
                                  "Image Should be less than ${image!.lengthSync() / 1000000 > appCtrl.usageControlsVal!.maxFileSize!}");
                              singleChatCtrl.isLoading = false;
                              singleChatCtrl.update();
                            } else {

                              singleChatCtrl
                                  .uploadMultipleFile(videoFile!, MessageType.image)
                                  .then((value) {
                                image = null;
                                videoFile = null;
                                update();

                              });
                            }
                            update();
                          });

                          image = File(videoFile!.path);
                          log("message::$image");
                          update();
                          singleChatCtrl.update();
                        }
                      } catch (e) {
                        singleChatCtrl.isLoading = false;
                        singleChatCtrl.update();
                      }
                    });
                    selectedImages = [];
                    update();
                  } else {
                    final broadcastCtrl = Get.find<BroadcastChatController>();
                    broadcastCtrl.selectedImages = value;
                    broadcastCtrl.selectedImages
                        .asMap()
                        .entries
                        .forEach((element) async {
                      File? videoFile = element.value;
                      try {
                        if (element.value.name.contains("mp4")) {
                          final light.LightCompressor lightCompressor =
                          light.LightCompressor();
                          final dynamic response =
                          await lightCompressor.compressVideo(
                            path: videoFile.path,
                            videoQuality: light.VideoQuality.very_low,
                            isMinBitrateCheckEnabled: false,
                            video: light.Video(videoName: element.value.name),
                            android: light.AndroidConfig(
                                isSharedStorage: true,
                                saveAt: light.SaveAt.Movies),
                            ios: light.IOSConfig(saveInGallery: false),
                          );

                          video = File(videoFile.path);
                          if (response is light.OnSuccess) {
                            log("videoFile!.path 1: ${getVideoSize(file: File(response.destinationPath))}}");
                            video = File(response.destinationPath);
                            broadcastCtrl
                                .uploadMultipleFile(video!, MessageType.video)
                                .then((value) {
                              video = null;
                              videoFile = null;
                              update();
                            });
                          } else {
                            broadcastCtrl.isLoading = false;
                            broadcastCtrl.update();
                            video = null;
                            videoFile = null;
                            update();
                          }
                        } else {
                          CompressObject compressObject = CompressObject(
                            imageFile: File(videoFile.path),
                            //image
                            targetPath: tempDir.path,
                            //compress to path
                            quality: 80,
                            //first compress quality, default 80
                            step: 9,
                            mode: CompressMode.AUTO, //default AUTO
                          );
                          // Luban.compressImage(compressObject).then((imagePath) {
                          //   image = File(imagePath!);
                          //   if (image!.lengthSync() / 1000000 >
                          //       appCtrl.usageControlsVal!.maxFileSize!) {
                          //     image = null;
                          //     snackBar(
                          //         "Image Should be less than ${image!.lengthSync() / 1000000 > appCtrl.usageControlsVal!.maxFileSize!}");
                          //     broadcastCtrl.isLoading = false;
                          //     broadcastCtrl.update();
                          //   } else {
                          //     broadcastCtrl
                          //         .uploadMultipleFile(image!, MessageType.image)
                          //         .then((value) {
                          //       image = null;
                          //       videoFile = null;
                          //       update();
                          //     });
                          //   }
                          //   update();
                          // });
                          image = File(compressObject.imageFile!.path);
                        }
                      } catch (e) {
                        broadcastCtrl.isLoading = false;
                        broadcastCtrl.update();
                      }
                    });
                    selectedImages = [];
                    update();
                  }
                }
              });
            }
            Get.back();
          });
        });
  }


  Future<File?> getImageFile(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return null;

    File file = File(pickedFile.path);

    // Optionally compress image here using CompressObject
    final tempDir = await getTemporaryDirectory();
    CompressObject compressObject = CompressObject(
      imageFile: file,
      targetPath: tempDir.path,
      quality: 80,
      step: 9,
      mode: CompressMode.AUTO,
    );

    File compressedFile = File(compressObject.imageFile!.path);
    return compressedFile;
  }
  onTapGroupProfile(BuildContext context,
      {isGroup = false, isSingleChat = false, isCreateGroup = false}) {
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
                      Text(appFonts.addPhoto.tr,
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
                ]).inkWell(onTap: () async {
                  if (isCreateGroup) {
                    getImage(ImageSource.gallery).then((value) {
                      final singleChatCtrl = Get.find<GroupMessageController>();
                      singleChatCtrl.uploadFile();
                    });
                  }
                  Get.back();
                }).paddingOnly(bottom: Insets.i30),
                Row(children: [
                  Image.asset(eImageAssets.camera, height: Sizes.s44),
                  const HSpace(Sizes.s15),
                  Text(appFonts.openCamera.tr,
                      style: AppCss.manropeBold14
                          .textColor(appCtrl.appTheme.darkText))
                ]).inkWell(onTap: () async {
                  dismissKeyboard();
                  await getImage(ImageSource.camera).then((value) {
                    final singleChatCtrl = Get.find<GroupMessageController>();
                    singleChatCtrl.uploadFile();
                  });
                  Get.back();
                }).paddingOnly(bottom: Insets.i30),
              ]).padding(horizontal: Sizes.s20, bottom: Insets.i20));
        });
  }

  //video picker option
  videoPickerOption(BuildContext context,
      {isGroup = false, isSingleChat = false}) {
    Get.back();
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.r25))),
        builder: (BuildContext context) {
          dismissKeyboard();
          // return your layout
          return ImagePickerLayout(cameraTap: () async {
            dismissKeyboard();

            await getVideo(ImageSource.camera).then((value) {
              if (isGroup) {
                final chatCtrl = Get.find<GroupChatMessageController>();
                chatCtrl.videoSend();
              } else if (isSingleChat) {
                log("janvi ::${isGroup}");
                final singleChatCtrl = Get.find<ChatController>();
                singleChatCtrl.videoSend();
              } else {
                final broadcastCtrl = Get.find<BroadcastChatController>();
                broadcastCtrl.videoSend();
              }
            });
            Get.back();
          }, galleryTap: () async {
            await getMultipleVideo().then((value) {
              if (isGroup) {
                final chatCtrl = Get.find<GroupChatMessageController>();
                chatCtrl.selectedImages = value;
                chatCtrl.selectedImages
                    .asMap()
                    .entries
                    .forEach((element) async {
                  File? videoFile = element.value;
                  File? video;
                  log("VIDEO FILE $videoFile");
                  if (element.value.name.contains("mp4")) {
                    final info = await VideoCompress.compressVideo(
                      videoFile.path,
                      quality: VideoQuality.MediumQuality,
                      deleteOrigin: false,
                      includeAudio: true,
                    );
                    video = File(info!.path!);
                  }
                  chatCtrl.uploadMultipleFile(video!, MessageType.video);
                });
                selectedImages = [];
                update();
                Get.back();
              } else if (isSingleChat) {
                final singleChatCtrl = Get.find<ChatController>();
                singleChatCtrl.selectedImages = value;
                singleChatCtrl.selectedImages
                    .asMap()
                    .entries
                    .forEach((element) async {
                  File? videoFile = element.value;
                  appCtrl.isLoading = true;
                  appCtrl.update();

                  if (element.value.name.contains("mp4")) {
                    final info = await VideoCompress.compressVideo(
                      videoFile.path,
                      quality: VideoQuality.MediumQuality,
                      deleteOrigin: false,
                      includeAudio: true,
                    );
                    video = File(info!.path!);
                  }
                  appCtrl.isLoading = false;
                  appCtrl.update();
                  singleChatCtrl.uploadMultipleFile(
                      videoFile, MessageType.video);
                });
                selectedImages = [];
                update();
                Get.back();
              } else {
                final broadcastCtrl = Get.find<BroadcastChatController>();
                broadcastCtrl.selectedImages = value;
                broadcastCtrl.selectedImages
                    .asMap()
                    .entries
                    .forEach((element) async {
                  File? videoFile = element.value;
                  if (element.value.name.contains("mp4")) {
                    final info = await VideoCompress.compressVideo(
                      videoFile.path,
                      quality: VideoQuality.MediumQuality,
                      deleteOrigin: false,
                      includeAudio: true,
                    );
                    video = File(info!.path!);
                  }
                  broadcastCtrl.uploadMultipleFile(
                      videoFile, MessageType.video);
                });
                selectedImages = [];
                update();
              }
            });
          });
        });
  }

  Future<String> uploadImage(File file, {String? fileNameText}) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference =
      FirebaseStorage.instance.ref().child(fileNameText ?? fileName);
      UploadTask uploadTask = reference.putFile(file);
      TaskSnapshot snap = await uploadTask;
      String downloadUrl = await snap.ref.getDownloadURL();
      imageUrl = downloadUrl;
      return imageUrl!;
    } on FirebaseException catch (e) {
      log("FIREBASE : ${e.message}");
      return "";
    }
  }

  // GET VIDEO FROM GALLERY
  Future getVideo(source) async {
    //  final light.LightCompressor lightCompressor = light.LightCompressor();
    // log("COMPRESSOR $lightCompressor}");
    final ImagePicker picker = ImagePicker();
    videoFile = (await picker.pickVideo(
      source: source,
    ));
    log("VideoFILEEEE $videoFile ");
    if (videoFile != null) {
      log("videoFile!.path : ${videoFile!.path}");
      appCtrl.isLoading = true;
      appCtrl.update();
      final info = await VideoCompress.compressVideo(
        videoFile!.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      /*final dynamic response = await lightCompressor.compressVideo(
        path: videoFile!.path,
        videoQuality: light.VideoQuality.very_low,
        isMinBitrateCheckEnabled: false,
        video: light.Video(videoName: videoFile!.name),
        android: light.AndroidConfig(
            isSharedStorage: true, saveAt: light.SaveAt.Movies),
        ios: light.IOSConfig(saveInGallery: false),
      )*/

      video = File(videoFile!.path);

      video = File(info!.path!);

      appCtrl.isLoading = false;
      appCtrl.update();
      update();
    }
    Get.forceAppUpdate();
  }
}