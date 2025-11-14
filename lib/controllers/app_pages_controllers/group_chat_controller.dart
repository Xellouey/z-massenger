import 'dart:async';
import 'dart:developer' as log;
import 'dart:io';
import 'dart:math';

// import 'package:chatzy/screens/app_screens/group_message_screen/layouts/group_clear_chat.dart';
import 'package:dartx/dartx_io.dart';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:encrypt/encrypt.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:chatzy/controllers/common_controllers/contact_controller.dart';
import 'package:swipe_to/swipe_to.dart';
import '../../config.dart';
import '../../models/call_model.dart';
import '../../screens/app_screens/chat_message/chat_message_api.dart';
import '../../screens/app_screens/chat_message/layouts/audio_recording_plugin.dart';
import '../../screens/app_screens/chat_message/layouts/image_picker.dart';

// import '../../screens/app_screens/group_message_screen/group_message_api.dart';
// import '../../screens/app_screens/group_message_screen/layouts/group_delete_alert.dart';
// import '../../screens/app_screens/group_message_screen/layouts/group_file_bottom_sheet.dart';
// import '../../screens/app_screens/group_message_screen/layouts/group_profile/exit_group_alert.dart';
// import '../../screens/app_screens/group_message_screen/layouts/group_receiver/group_receiver_message.dart';
// import '../../screens/app_screens/group_message_screen/layouts/group_sender/sender_message.dart';
import '../../screens/app_screens/group_message_screen/group_message_api.dart';
import '../../screens/app_screens/group_message_screen/layouts/group_clear_chat.dart';
import '../../screens/app_screens/group_message_screen/layouts/group_delete_alert.dart';
import '../../screens/app_screens/group_message_screen/layouts/group_file_bottom_sheet.dart';
import '../../screens/app_screens/group_message_screen/layouts/group_profile/exit_group_alert.dart';
import '../../screens/app_screens/group_message_screen/layouts/group_receiver/group_receiver_message.dart';
import '../../screens/app_screens/group_message_screen/layouts/group_sender/sender_message.dart';
import '../../screens/app_screens/select_contact_screen/fetch_contacts.dart';
import '../../utils/general_utils.dart';
import '../../widgets/common_note_encrypt.dart';
import '../../widgets/reaction_pop_up/emoji_picker_widget.dart';
import '../bottom_controllers/picker_controller.dart';
import '../common_controllers/all_permission_handler.dart';
import '../recent_chat_controller.dart';

class GroupChatMessageController extends GetxController {
  String? pId,
      id,
      documentId,
      pName,
      groupImage,
      imageUrl,
      status,
      statusLastSeen,
      nameList,
      videoUrl,
      backgroundImage;
  dynamic pData, allData;
  dynamic selectedWallpaper;
  List message = [];
  bool positionStreamStarted = false, isLock = false;
  bool isFilter = false;
  bool isCallFilter = false;
  int pageSize = 20;
  String? wallPaperType, deleteOption;
  XFile? imageFile, videoFile;
  List userList = [];
  List searchUserList = [];
  List selectedIndexId = [], multipleSelectedIndex = [];
  List searchChatId = [];
  List<File> selectedImages = [];
  File? image;
  bool isLoading = true,
      isTextBox = false,
      isDescTextBox = false,
      isThere = false,
      typing = false,
      isChatSearch = false;
  dynamic user;
  bool isShowSticker = false, isEmoji = false;
  final permissionHandelCtrl = Get.isRegistered<PermissionHandlerController>()
      ? Get.find<PermissionHandlerController>()
      : Get.put(PermissionHandlerController());
  final pickerCtrl = Get.isRegistered<PickerController>()
      ? Get.find<PickerController>()
      : Get.put(PickerController());
  TextEditingController textEditingController = TextEditingController();
  TextEditingController textNameController = TextEditingController();
  TextEditingController textDescController = TextEditingController();
  TextEditingController textSearchController = TextEditingController();
  TextEditingController txtChatSearch = TextEditingController();
  ScrollController listScrollController =
  ScrollController(initialScrollOffset: 0);
  FocusNode focusNode = FocusNode();
  bool enableReactionPopup = false;
  bool showPopUp = false;
  int? count;
  StreamSubscription? messageSub;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> allMessages = [];
  List<DateTimeChip> localMessage = [];
  late encrypt.Encrypter cryptor;
  Offset tapPosition = Offset.zero;
  final iv = encrypt.IV.fromLength(8);
  List groupOptionLists = [];

  List mediaList = [
    appFonts.mediaFile,
    appFonts.documentFile,
    appFonts.linkFile
  ];
  List<MessageModel> selectedContent = [];

  forwardMessage() async {
    log.log("selectedContent::$selectedContent");
    Get.toNamed(routeName.forwardList, arguments: selectedContent)!.then(
          (value) {
        selectedIndexId = [];
        selectedContent = [];
        multipleSelectedIndex = [];
        update();
      },
    );
  }

  @override
  void onInit() {
    // TODO: implement onInit
    groupOptionLists = appArray.groupOptionList;
    user = appCtrl.storage.read(session.user);
    id = user["id"];
    isLoading = false;
    imageUrl = '';
    listScrollController = ScrollController(initialScrollOffset: 0);
    var data = Get.arguments;
    pData = data;
    if (pData != null) {
      print("object::pData:$pData");
      pId = pData["message"]["groupId"];
      pName = pData["groupData"]["name"];
      groupImage = pData["groupData"]["image"];
      userList = pData["message"]["receiverId"];
      loadChatWallpaper (pId!);
    }
    textNameController.text = pName!;
    update();
    getPeerStatus();
    update();
    super.onInit();
  }

  showBottomSheet() => EmojiPickerWidget(
      controller: textEditingController,
      onSelected: (emoji) {
        textEditingController.text + emoji;
        isEmoji = true;
        update();
      });


  void loadChatWallpaper(String chatId) {
    selectedWallpaper = appCtrl.storage.read("backgroundImage_$chatId")?? eImageAssets.bg11;
    update();
  }
  //pick up contact and share
  saveContactInChat() async {
    PermissionStatus permissionStatus =
    await permissionHandelCtrl.getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      Get.to(() => FetchContact(prefs: appCtrl.pref), arguments: true)!
          .then((value) async {
        if (value != null) {
          var contact = value;
          isLoading = false;
          update();
          onSendMessage(
              '${contact["name"]}-BREAK-${contact["number"]}-BREAK-${contact["photo"]}',
              MessageType.contact);
        }
      });
    } else {
      permissionHandelCtrl.handleInvalidPermissions(permissionStatus);
    }
    update();
  }

//get group data
  getPeerStatus() async {
    nameList = "";
    nameList = null;

    FirebaseFirestore.instance
        .collection(collectionName.groups)
        .doc(pId)
        .get()
        .then((value) async {
      if (value.exists) {
        allData = value.data();
        update();
        backgroundImage = value.data()!['backgroundImage'] ?? "";
        List receiver = pData["groupData"]["users"] ?? [];

        nameList = (receiver.length - 1).toString();
        if (pData["message"]["senderId"] != user["id"]) {
          await FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(appCtrl.user["id"])
              .collection(collectionName.groupMessage)
              .doc(pId)
              .collection(collectionName.chat)
              .get()
              .then((value) {
            value.docs.asMap().entries.forEach((element) async {
              if (element.value.exists) {
                if (element.value.data()["sender"] != user["id"]) {
                  List seenMessageList =
                      element.value.data()["seenMessageList"] ?? [];

                  bool isAvailable = seenMessageList
                      .where((availableElement) =>
                  availableElement["userId"] == user["id"])
                      .isNotEmpty;
                  if (!isAvailable) {
                    var data = {
                      "userId": user["id"],
                      "date": DateTime.now().millisecondsSinceEpoch
                    };

                    seenMessageList.add(data);
                  }
                  await FirebaseFirestore.instance
                      .collection(collectionName.users)
                      .doc(appCtrl.user["id"])
                      .collection(collectionName.groupMessage)
                      .doc(pId)
                      .collection(collectionName.chat)
                      .doc(element.value.id)
                      .update({"seenMessageList": seenMessageList});

                  await FirebaseFirestore.instance
                      .collection(collectionName.users)
                      .doc(user["id"])
                      .collection(collectionName.chats)
                      .where("groupId", isEqualTo: pId)
                      .limit(1)
                      .get()
                      .then((userChat) async {
                    if (userChat.docs.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection(collectionName.users)
                          .doc(user["id"])
                          .collection(collectionName.chats)
                          .doc(userChat.docs[0].id)
                          .update({"seenMessageList": seenMessageList});
                    }
                  });
                }
              }
            });
          });
        }
      }
    });

    messageSub = FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(appCtrl.user["id"])
        .collection(collectionName.groupMessage)
        .doc(pId)
        .collection(collectionName.chat)
        .snapshots()
        .listen((event) async {
      log.log("event.docs::${event.docs[0].data()}");
      allMessages = event.docs;
      update();

      ChatMessageApi().getLocalGroupMessage();

      isLoading = false;
      update();
    });
    isLoading = false;
    update();
    user = appCtrl.storage.read(session.user);
    if (backgroundImage != null || backgroundImage != "") {
      FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(user["id"])
          .get()
          .then((value) {
        if (value.exists) {
          backgroundImage = value.data()!["backgroundImage"] ?? "";
        }
        update();
      });
    }

    FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(appCtrl.user["id"])
        .collection(collectionName.groupMessage)
        .doc(pId)
        .collection(collectionName.chat)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        documentId = value.docs[0].id;
      }
    });

    FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(appCtrl.user["id"])
        .collection(collectionName.chats)
        .where("groupId", isEqualTo: pId)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        isLock = value.docs[0].data()['isLock'] ?? false;
      }
      update();
    });

    return status;
  }

  onTapStatus() {
    callAlertDialog(
        title: appFonts.selectCallType,
        list: appArray.callList,
        onTap: (int index) async {
          if (index == 0) {
            await permissionHandelCtrl
                .getCameraMicrophonePermissions()
                .then((value) {
              if (value == true) {
                audioAndVideoCall(false);
              }
            });
          } else {
            await permissionHandelCtrl
                .getCameraMicrophonePermissions()
                .then((value) {
              if (value == true) {
                audioAndVideoCall(true);
              }
            });
          }
        });
  }

  //clear dialog
  clearChatConfirmation() async {
    Get.generalDialog(
      pageBuilder: (context, anim1, anim2) {
        return const GroupClearDialog();
      },
    );
  }

  //delete dialog
  deleteChatConfirmation() async {
    Get.generalDialog(
      pageBuilder: (context, anim1, anim2) {
        return const GroupDeleteDialog();
      },
    );
  }

  onTapDots() {
    isFilter = !isFilter;
    update();
  }

  onTapCallDots() {
    isCallFilter = !isCallFilter;
    update();
  }

  //group call
  audioAndVideoCall(isVideoCall) async {
    try {
      var userData = appCtrl.storage.read(session.user);
      Map<String, dynamic>? response =
      await firebaseCtrl.getAgoraTokenAndChannelName();

      log.log("FUNCTION ; $response");
      if (response != null) {
        String channelId = response["channelName"];
        String token = response["agoraToken"];
        int timestamp = DateTime.now().millisecondsSinceEpoch;
        List receiver = pData["groupData"]["users"];

        receiver.asMap().entries.forEach((element) {
          // Пропускаем текущего пользователя (нельзя звонить самому себе)
          if (element.value["id"] == userData["id"]) {
            log.log("Skipping self in group call");
            return;
          }

          FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(element.value["id"])
              .get()
              .then((snap) async {
            Call call = Call(
                timestamp: timestamp,
                callerId: userData["id"],
                callerName: userData["name"],
                callerPic: userData["image"],
                receiverId: snap.data()!["id"],
                receiverName: snap.data()!["name"],
                receiverPic: snap.data()!["image"],
                callerToken: userData["pushToken"],
                receiverToken: snap.data()!["pushToken"],
                channelId: channelId,
                isVideoCall: isVideoCall,
                isGroup: true,
                groupName: pName,
                receiver: receiver,
                agoraToken: token);

            await FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call.callerId)
                .collection(collectionName.calling)
                .add({
              "timestamp": timestamp,
              "callerId": userData["id"],
              "callerName": userData["name"],
              "callerPic": userData["image"],
              "receiverId": snap.data()!["id"],
              "receiverName": snap.data()!["name"],
              "receiverPic": snap.data()!["image"],
              "callerToken": userData["pushToken"],
              "receiverToken": snap.data()!["pushToken"],
              "hasDialled": true,
              "channelId": channelId,
              "agoraToken": token,
              "isGroup": true,
              "groupName": pName,
              "isVideoCall": isVideoCall,
            }).then((value) async {
              await FirebaseFirestore.instance
                  .collection(collectionName.calls)
                  .doc(call.receiverId)
                  .collection(collectionName.calling)
                  .add({
                "timestamp": timestamp,
                "callerId": userData["id"],
                "callerName": userData["name"],
                "callerPic": userData["image"],
                "receiverId": snap.data()!["id"],
                "receiverName": snap.data()!["name"],
                "receiverPic": snap.data()!["image"],
                "callerToken": userData["pushToken"],
                "receiverToken": snap.data()!["pushToken"],
                "hasDialled": false,
                "channelId": channelId,
                "agoraToken": token,
                "isGroup": true,
                "groupName": pName,
                "isVideoCall": isVideoCall
              }).then((value) async {
                call.hasDialled = true;
                if (isVideoCall == false) {
                  firebaseCtrl.sendNotification(
                      notificationType: 'call',
                      title: "Входящий аудиозвонок...",
                      msg: "${call.callerName} звонит!",
                      token: call.receiverToken,
                      pName: call.callerName,
                      image: userData["image"],
                      dataTitle: call.callerName);
                  var data = {
                    "channelName": call.channelId,
                    "call": call,
                    "token": response["agoraToken"]
                  };
                  Get.toNamed(routeName.audioCall, arguments: data);
                } else {
                  firebaseCtrl.sendNotification(
                      notificationType: 'call',
                      title: "Входящий видеозвонок...",
                      msg: "${call.callerName} звонит!",
                      token: call.receiverToken,
                      pName: call.callerName,
                      image: userData["image"],
                      dataTitle: call.callerName);

                  var data = {
                    "channelName": call.channelId,
                    "call": call,
                    "token": response["agoraToken"]
                  };

                  Get.toNamed(routeName.videoCall, arguments: data);
                }
              });
            });
          });
        });
      } else {
        Fluttertoast.showToast(msg: "Не удалось позвонить");
      }
    } on FirebaseException catch (e) {
      // Caught an exception from Firebase.
      log.log("err :$e");
    }
  }

  //document share
  documentShare() async {
    pickerCtrl.dismissKeyboard();
    Get.back();
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      isLoading = true;
      update();
      File file = File(result.files.single.path.toString());
      String fileName =
          "${file.name}-${DateTime.now().millisecondsSinceEpoch.toString()}";
      Reference reference = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = reference.putFile(file);

      uploadTask.then((res) {
        res.ref.getDownloadURL().then((downloadUrl) {
          imageUrl = downloadUrl;

          isLoading = false;
          onSendMessage(
              "${result.files.single.name}-BREAK-$imageUrl",
              result.files.single.path.toString().contains(".mp4")
                  ? MessageType.video
                  : result.files.single.path.toString().contains(".mp3")
                  ? MessageType.audio
                  : MessageType.doc);
          update();
        }, onError: (err) {
          isLoading = false;
          update();
          Fluttertoast.showToast(msg: 'Not Upload');
        });
      });
    }
  }

  //location share
  locationShare() async {
    pickerCtrl.dismissKeyboard();
    Get.back();

    await permissionHandelCtrl.getCurrentPosition().then((value) async {
      var locationString =
          'https://www.google.com/maps/search/?api=1&query=${value!.latitude},${value.longitude}';
      onSendMessage(locationString, MessageType.location);
      return null;
    });
  }

  //share media
  shareMedia(BuildContext context) {
    showModalBottomSheet(
        backgroundColor: appCtrl.appTheme.trans,
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.r25)),
        ),
        builder: (BuildContext context) {
          return const GroupBottomSheet();
        });
  }

// UPLOAD SELECTED IMAGE TO FIREBASE
  Future uploadFile({isGroupImage = false, groupImageFile}) async {
    imageFile = pickerCtrl.imageFile;
    isLoading = true;
    update();
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref().child(fileName);
    var file = File(!isGroupImage ? imageFile!.path : groupImageFile.path);
    UploadTask uploadTask = reference.putFile(file);
    print("object::$file");
    uploadTask.then((res) {
      res.ref.getDownloadURL().then((downloadUrl) async {
        imageUrl = downloadUrl;
        isLoading = false;
        if (isGroupImage) {
          await FirebaseFirestore.instance
              .collection(collectionName.groups)
              .doc(pId)
              .update({'image': imageUrl}).then((value) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(user["id"])
                .get()
                .then((snap) async {
              groupImage = imageUrl;
              update();
            });
          });
          debugPrint("imageUrl1::$imageUrl");
        } else {
          onSendMessage(imageUrl!, MessageType.image);
          debugPrint("imageUrl::$imageUrl");
        }
        update();
      }, onError: (err) {
        isLoading = false;
        update();
        Fluttertoast.showToast(msg: 'Image is Not Valid');
      });
    });
  }

// UPLOAD SELECTED IMAGE TO FIREBASE
  Future uploadMultipleFile(File imageFile, MessageType messageType) async {
    imageFile = imageFile;
    update();
    log.log("imageUrl::$imageFile///$messageType");
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref().child(fileName);
    var file = File(imageFile.path);
    UploadTask uploadTask = reference.putFile(file);
    log.log("uploadTask::$uploadTask");
    uploadTask.then((res) {
      log.log("downloadUrl::$res");
      res.ref.getDownloadURL().then((downloadUrl) async {
        imageUrl = downloadUrl;
        isLoading = false;
        onSendMessage(imageUrl!, messageType);
        update();
      }, onError: (err) {
        isLoading = false;
        update();
        Fluttertoast.showToast(msg: 'Image is Not Valid');
      });
    });
  }

  Future videoSend() async {
    videoFile = pickerCtrl.videoFile;
    isLoading = true;
    update();
    if (videoFile != null) {
      const Duration(seconds: 2);
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference = FirebaseStorage.instance.ref().child(fileName);
      print("reference::$reference");
      var file = File(videoFile!.path);
      UploadTask uploadTask = reference.putFile(file);

      uploadTask.then((res) {
        res.ref.getDownloadURL().then((downloadUrl) {
          videoUrl = downloadUrl;
          isLoading = false;
          pickerCtrl.videoFile = null;
          pickerCtrl.video = null;
          update();
          pickerCtrl.update();
          onSendMessage(videoUrl!, MessageType.video);

          pickerCtrl.dismissKeyboard();
          update();
        }, onError: (err) {
          isLoading = false;
          update();
          Fluttertoast.showToast(msg: 'Image is Not Valid');
        });
      }).then((value) {
        videoFile = null;
        pickerCtrl.videoFile = null;

        pickerCtrl.video = null;
        videoUrl = "";
        update();
        pickerCtrl.update();
      });
    }
  }

  //audio recording
  void audioRecording(String type, int index) {
    showModalBottomSheet(
      context: Get.context!,
      isDismissible: false,
      backgroundColor: appCtrl.appTheme.trans,
      builder: (BuildContext bc) {
        return Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: appCtrl.appTheme.white,
                borderRadius: BorderRadius.circular(10)),
            child: AudioRecordingPlugin(type: type, index: index));
      },
    ).then((value) async {
      if (value != null) {
        File file = File(value);

        isLoading = true;
        update();
        String fileName =
            "${file.name}-${DateTime.now().millisecondsSinceEpoch.toString()}";
        Reference reference = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = reference.putFile(file);
        TaskSnapshot snap = await uploadTask;
        String downloadUrl = await snap.ref.getDownloadURL();

        isLoading = false;
        update();
        onSendMessage(downloadUrl, MessageType.audio);
      }
    });
  }
  List<UserContactModel> registeredContacts = [];

  // Add this helper function
  String getSenderNameFromId(String? senderId) {
    log.log("SENDERID::${senderId}");
    if (senderId == null || senderId.isEmpty) return "Unknown";

    final contact = registeredContacts.firstWhere(
          (e) => e.uid == senderId,

    );
    log.log("contact:::$contact");
    return contact.username!;

  }
  // SEND MESSAGE CLICK
  // void onSendMessage(String content, MessageType type, {groupId}) async {
  //   isLoading = true;
  //   textEditingController.clear();
  //
  //   update();
  //   Encrypted encrypteded = encryptFun(content);
  //   String encrypted = encrypteded.base64;
  //   isEmoji = false;
  //   if (content.trim() != '') {
  //     replyMessage = null;
  //     var user = appCtrl.storage.read(session.user);
  //     id = user["id"];
  //     String time = DateTime.now().millisecondsSinceEpoch.toString();
  //
  //     int index = localMessage.indexWhere((element) => element.time == "Today");
  //     MessageModel messageModel = MessageModel(
  //         blockBy: allData != null ? allData["blockBy"] : "",
  //         blockUserId: allData != null ? allData["blockUserId"] : "",
  //         chatId: pId,
  //         content: encrypted,
  //         docId: time,
  //         isBlock: false,
  //         isBroadcast: false,
  //         isFavourite: false,
  //         isSeen: false,
  //         messageType: "sender",
  //         receiver: pId,
  //         sender: appCtrl.user["id"],
  //         replyTo: newMessage != null ? newMessage!.content : "",
  //         replyType: newMessage != null ? newMessage!.type : "",
  //         replyBy:newMessage != null ? newMessage!.sender : "",
  //         timestamp: time,
  //         type: type.name);
  //     bool isEmpty =
  //         localMessage.where((element) => element.time == "Today").isEmpty;
  //     if (isEmpty) {
  //       List<MessageModel>? message = [];
  //       if (message.isNotEmpty) {
  //         message.add(messageModel);
  //         message[0].docId = time;
  //       } else {
  //         message = [messageModel];
  //         message[0].docId = time;
  //       }
  //       DateTimeChip dateTimeChip =
  //       DateTimeChip(time: getDate(time), message: message);
  //       localMessage.add(dateTimeChip);
  //     } else {
  //       localMessage[index].message =
  //           localMessage[index].message!.reversed.toList();
  //       if (!localMessage[index].message!.contains(messageModel)) {
  //         localMessage[index].message!.add(messageModel);
  //       }
  //       localMessage[index].message =
  //           localMessage[index].message!.reversed.toList();
  //     }
  //     Get.forceAppUpdate();
  //     await GroupMessageApi().saveGroupMessage(encrypted,
  //         type,
  //         replyType: newMessage != null ? getMessageType(newMessage!.type):null,
  //         reply: newMessage!=null? newMessage!.content:"",
  //         senderId: newMessage!=null? newMessage!.sender:"");
  //
  //     await ChatMessageApi()
  //         .saveGroupData(id, pId, encrypted, pData, type, groupImage);
  //
  //     isLoading = false;
  //     videoFile = null;
  //     videoUrl = "";
  //     pickerCtrl.videoFile = null;
  //
  //     pickerCtrl.video = null;
  //     update();
  //     pickerCtrl.update();
  //     update();
  //   }
  // }
  void onSendMessage(String content, MessageType type, {groupId}) async {
    textEditingController.clear();
    update();

    Encrypted encrypteded = encryptFun(content);
    String encrypted = encrypteded.base64;
    isEmoji = false;

    // Correct way to assign the reply message
    newMessage = replyMessage;

    if (content.trim() != '') {
      var user = appCtrl.storage.read(session.user);
      id = user["id"];

      String time = DateTime.now().millisecondsSinceEpoch.toString();

      MessageModel messageModel = MessageModel(
        blockBy: allData != null ? allData["blockBy"] : "",
        blockUserId: allData != null ? allData["blockUserId"] : "",
        chatId: pId,
        content: encrypted,
        docId: time,
        isBlock: false,
        isBroadcast: false,
        isFavourite: false,
        isSeen: false,
        messageType: "sender",
        receiver: pId,
        sender: appCtrl.user["id"],
        replyTo: newMessage?.content ?? "",
        replyType: newMessage?.type,
        replyBy: newMessage?.sender ?? "",
        timestamp: time,
        originalSenderName: newMessage?.senderName,
        type: type.name,
      );

      // Add message to localMessage list
      int index = localMessage.indexWhere((element) => element.time == "Today");
      bool isEmpty = localMessage.where((element) => element.time == "Today").isEmpty;

      if (isEmpty) {
        List<MessageModel> message = [messageModel];
        DateTimeChip dateTimeChip = DateTimeChip(time: getDate(time), message: message);
        localMessage.add(dateTimeChip);
        update();
      } else {
        localMessage[index].message = localMessage[index].message!.reversed.toList();
        if (!localMessage[index].message!.contains(messageModel)) {
          localMessage[index].message!.add(messageModel);
        }
        update();
        localMessage[index].message = localMessage[index].message!.reversed.toList();
        Get.forceAppUpdate();
      }

      update();
      Get.forceAppUpdate();

      await GroupMessageApi().saveGroupMessage(
        encrypted, type,
        replyType: newMessage?.type,
        reply: newMessage?.content ?? "",
        senderId: newMessage?.sender ?? "",
        originalSenderName: newMessage?.senderName ?? getSenderNameFromId(newMessage?.sender),
      );

      await ChatMessageApi().saveGroupData(id, pId, encrypted, pData, type, groupImage);

      /// ✅ Clear the reply message after sending
      replyMessage = null;
      newMessage = null;

      isLoading = false;
      videoFile = null;
      videoUrl = "";
      pickerCtrl.videoFile = null;
      pickerCtrl.video = null;

      update();
      pickerCtrl.update();
      update();
    }
  }

/*  void onSendMessage(String content, MessageType type, {groupId}) async {
    // isLoading = true;
    textEditingController.clear();
    update();
    Encrypted encrypteded = encryptFun(content);
    String encrypted = encrypteded.base64;
    isEmoji = false;
    // newMessage = replyMessage;

    if(replyMessage != "" && replyMessage != null) {newMessage = replyMessage;

    }
    else{
      newMessage;
    }
    // log.log("${newMessage} ${newMessage!.senderName!}");
    if (content.trim() != '') {
      textEditingController.clear();
      var user = appCtrl.storage.read(session.user);
      id = user["id"];
      replyMessage = null;
      String time = DateTime.now().millisecondsSinceEpoch.toString();
log.log("replyMessage?.senderName::${newMessage?.senderName}");
      int index = localMessage.indexWhere((element) => element.time == "Today");
      MessageModel messageModel = MessageModel(
          blockBy: allData != null ? allData["blockBy"] : "",
          blockUserId: allData != null ? allData["blockUserId"] : "",
          chatId: pId,
          content: encrypted,
          docId: time,
          isBlock: false,
          isBroadcast: false,
          isFavourite: false,
          isSeen: false,
          messageType: "sender",
          receiver: pId,
          sender: appCtrl.user["id"],
          replyTo: newMessage != null ? newMessage!.content : "",
          replyType: newMessage?.type,
          replyBy: newMessage != null ? newMessage!.sender : "",
          timestamp: time,
          originalSenderName: newMessage?.senderName ?? getSenderNameFromId(newMessage?.sender),
          type: type.name);
      // log.log("getSenderNameFromId(newMessage?.sender)::${getSenderNameFromId(newMessage?.sender)}");
      bool isEmpty =
          localMessage.where((element) => element.time == "Today").isEmpty;
      if (isEmpty) {
        List<MessageModel>? message = [];
        if (message.isNotEmpty) {
          message.add(messageModel);
          message[0].docId = time;
        } else {
          message = [messageModel];
          message[0].docId = time;
        }
        DateTimeChip dateTimeChip =
            DateTimeChip(time: getDate(time), message: message);
        localMessage.add(dateTimeChip);
        update();
      } else {
        localMessage[index].message =
            localMessage[index].message!.reversed.toList();
        if (!localMessage[index].message!.contains(messageModel)) {
          localMessage[index].message!.add(messageModel);
        }
        update();
        localMessage[index].message =
            localMessage[index].message!.reversed.toList();
        Get.forceAppUpdate();
      }
      update();
      Get.forceAppUpdate();
      await GroupMessageApi().saveGroupMessage(encrypted, type,
          replyType: newMessage?.type,

          reply: newMessage != null ? newMessage!.content : "",
          senderId: newMessage != null ? newMessage!.sender : "",  originalSenderName: newMessage?.senderName ?? getSenderNameFromId(newMessage?.sender),
      );
      log.log(
          "group new message${newMessage!.content} /// ${getMessageType(newMessage!.type)} /// ${newMessage!.senderName}");

      await ChatMessageApi()
          .saveGroupData(id, pId, encrypted, pData, type, groupImage);

      isLoading = false;
      videoFile = null;
      videoUrl = "";
      pickerCtrl.videoFile = null;

      pickerCtrl.video = null;
      update();
      pickerCtrl.update();
      update();
    }
  }*/

  void scrollToBottom() {
    if (listScrollController.hasClients) {
      listScrollController.animateTo(
        listScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  //delete chat layout
  buildPopupDialog() async {
    await showDialog(
        context: Get.context!, builder: (_) => const GroupDeleteAlert());
  }

  Widget timeLayout() {
    return GetBuilder<GroupChatMessageController>(builder: (chatCtrl) {
      return Column(
          children: localMessage.reversed.toList().asMap().entries.map((a) {
            List<MessageModel> newMessageList = a.value.message!.toList();
            return Column(
              children: [
                Text(
                    a.value.time!.contains("-other")
                        ? a.value.time!.split("-other")[0]
                        : a.value.time!,
                    style: AppCss.manropeMedium14
                        .textColor(appCtrl.appTheme.greyText))
                    .marginSymmetric(vertical: Insets.i5),
                ...newMessageList.reversed.toList().asMap().entries.map((e) {
                  return buildItem(
                      e.key,
                      e.value,
                      e.value.docId,
                      a.value.time!.contains("-other")
                          ? a.value.time!.split("-other")[0]
                          : a.value.time!);
                })
              ],
            );
          }).toList());
    });
  }

// BUILD ITEM MESSAGE BOX FOR RECEIVER AND SENDER BOX DESIGN
  Widget buildItem(int index, MessageModel document, docId, title) {
    return Column(children: [
      document.type == MessageType.note.name
          ? const CommonNoteEncrypt()
          : Container(),
      (document.sender == user["id"])
          ? SwipeTo(
          onRightSwipe: (details) {
            log.log(
                "replyMessage!.senderName! ::: $details////${document.senderName}///${document.sender}////${user["id"]}");

            Get.forceAppUpdate();

            replyToMessage(document);
          },
          child: GroupSenderMessage(
              document: document,
              docId: docId,
              index: index,
              title: title,
              currentUserId: user["id"])
              .inkWell(onTap: () {
            enableReactionPopup = false;
            showPopUp = false;
            selectedIndexId = [];
            update();
          }))
          : document.sender != user["id"]
          ?
      // RECEIVER MESSAGE
      SwipeTo(
        onRightSwipe: (details) {
          debugPrint(
              "replyMessage!.senderName! name ::: }////${document.senderName}///${document.content}");
          replyToMessage(document);
        },
        child: GroupReceiverMessage(
          document: document,
          title: title,
          index: index,
          // docId: docId,
          docId: document.docId,
        ).inkWell(onTap: () {
          enableReactionPopup = false;
          showPopUp = false;
          selectedIndexId = [];
          update();
        }),
      )
          : Container()
    ]);
  }

  MessageModel? replyMessage;
  MessageModel? newMessage;
  VoidCallBack? onCancelReply;
  MessageModel? selectedMessage; // The selected message for replying


  replyToMessage(MessageModel message) {
    if (message.senderName == null || message.senderName!.isEmpty) {
      message.senderName = getSenderNameFromId(message.sender);
    }

    log.log("Replying to message from: ${message.senderName}");
    replyMessage = message;
    update();
  }
  // replyToMessage(MessageModel message) {
  //   log.log("message:::${message.senderName}");
  //   replyMessage = message;
  //   update();
  // }

  cancelReply() {
    replyMessage = null;
    update();
  }

  // ON BACK PRESS
  onBackPress() {
    appCtrl.isTyping = false;
    appCtrl.update();
    firebaseCtrl.groupTypingStatus(pId, false);
    FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(appCtrl.user["id"])
        .collection(collectionName.messages)
        .doc(pId)
        .collection(collectionName.chat)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        if (value.docs.length == 1) {
          FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(appCtrl.user["id"])
              .collection(collectionName.messages)
              .doc(pId)
              .collection(collectionName.chat)
              .doc(value.docs[0].id)
              .delete();
        }
      }
    });
    Get.back();
  }

  //ON LONG PRESS
  onLongPressFunction(docId, title, MessageModel message) {
    showPopUp = true;
    enableReactionPopup = true;
    var value = {"title": title, "docId": docId};
    if (!selectedIndexId.contains(docId)) {
      if (showPopUp == false) {
        multipleSelectedIndex.add(value);
        selectedContent.add(message);
        selectedIndexId.add(docId);
      } else {
        selectedIndexId = [];
        multipleSelectedIndex = [];
        multipleSelectedIndex.add(value);
        selectedContent.add(message);
        selectedIndexId.add(docId);
      }
      update();
    }
    update();
  }

  //exit group


  //delete chat layout
  exitGroupDialog() async {
    await showDialog(
        context: Get.context!,
        builder: (_) => ExitGroupAlert(
          name: pName,
        ));
  }

  //delete group
  deleteGroup() async {
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(user["id"])
        .collection(collectionName.chats)
        .where("groupId", isEqualTo: pId)
        .limit(1)
        .get()
        .then((value) async {
      if (value.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(user["id"])
            .collection(collectionName.chats)
            .doc(value.docs[0].id)
            .delete()
            .then((value) {
          Get.back();
          Get.back();
        });
      }
    });
  }

// GET IMAGE FROM GALLERY
  Future getImage(source) async {
    final ImagePicker picker = ImagePicker();
    imageFile = (await picker.pickImage(source: source))!;
    log.log("imageFile::$imageFile");
    isLoading = true;
    update();
    if (imageFile != null) {
      update();
      uploadFile(isGroupImage: true, groupImageFile: imageFile);
      update();
    }
  }

  //image picker option
  imagePickerOption(BuildContext context) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.r25)),
        ),
        builder: (BuildContext context) {
          // return your layout
          return ImagePickerLayout(cameraTap: () {
            getImage(ImageSource.camera);
            Get.back();
          }, galleryTap: () {
            debugPrint("IMAGE::${ImageSource.gallery}");
            getImage(ImageSource.gallery);
            Get.back();
          });
        });
  }

  Future<void> checkPermission(String typeName, int index) async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    } else {
      audioRecording(typeName, index);
    }
  }

  //check contact in firebase and if not exists
  saveContact(userData, {message}) async {
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(user["id"])
        .collection("chats")
        .where("isOneToOne", isEqualTo: true)
        .get()
        .then((value) {
      bool isEmpty = value.docs
          .where((element) =>
      element.data()["senderId"] == userData["uid"] ||
          element.data()["receiverId"] == userData["uid"])
          .isNotEmpty;
      if (!isEmpty) {
        var data = {"chatId": "0", "data": userData, "message": message};

        Get.back();
        Get.toNamed(routeName.chatLayout, arguments: data);
      } else {
        value.docs.asMap().entries.forEach((element) {
          if (element.value.data()["senderId"] == userData["uid"] ||
              element.value.data()["receiverId"] == userData["uid"]) {
            var data = {
              "chatId": element.value.data()["chatId"],
              "data": userData,
              "message": message
            };
            Get.back();

            Get.toNamed(routeName.chatLayout, arguments: data);
          }
        });

        //
      }
    });
  }

  /*removeUserFromGroup(value, snapshot) async {
    final groupDocRef = FirebaseFirestore.instance.collection(collectionName.groups).doc(pId);

    await groupDocRef.get().then((group) async {
      if (group.exists) {
        List user = List.from(group.data()!["users"]);
        Map<String, dynamic> removedUsers = Map<String, dynamic>.from(group.data()?["removedUsers"] ?? {});

        // Find user chatId if exists somewhere (depends on your data structure)
        // Assuming you have a way to get chatId for the user in group
        // For example, user object may contain "chatId", if not you need to fetch it.

        var userToRemove = user.firstWhere((element) => element["phone"] == value["phone"], orElse: () => null);
        if (userToRemove != null) {
          String removedUserId = userToRemove["id"];
          String oldChatId = userToRemove["chatId"] ?? ""; // Adjust accordingly

          // Remove user from users list
          user.removeWhere((element) => element["phone"] == value["phone"]);

          // Store removed user with their old chatId
          removedUsers[removedUserId] = oldChatId;

          // Update group document with new users list and removedUsers map
          await groupDocRef.update({
            "users": user,
            "removedUsers": removedUsers,
          });

          update();
          getPeerStatus();
        }
      }
    });
  }*/

  removeUserFromGroup(value, snapshot) async {
    final groupDoc = await FirebaseFirestore.instance
        .collection(collectionName.groups)
        .doc(pId)
        .get();

    if (groupDoc.exists) {
      List currentUsers = groupDoc.data()?["users"] ?? [];

      // Fetch and normalize removedUsers as List<Map<String, dynamic>>
      dynamic rawRemoved = groupDoc.data()?["removedUsers"];
      List<Map<String, dynamic>> removedUsers = [];

      if (rawRemoved is List) {
        removedUsers = List<Map<String, dynamic>>.from(rawRemoved);
      } else if (rawRemoved is Map) {
        removedUsers = rawRemoved.entries
            .map((entry) => {
          "id": entry.key,
          "chatId": entry.value,
        })
            .toList();
      }

      // Get the current chat ID from user's chat collection
      List chats = await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(value["id"])
          .collection(collectionName.chats)
          .where("groupId", isEqualTo: pId)
          .limit(1)
          .get()
          .then((snap) => snap.docs.map((e) => e.id).toList());

      if (chats.isNotEmpty) {
        // Check if already stored, if not, add it
        if (!removedUsers.any((u) => u["id"] == value["id"])) {
          removedUsers.add({
            "id": value["id"],
            "chatId": chats.first,
          });
        }
      }

      // Remove user from current user list
      currentUsers.removeWhere((e) => e["id"] == value["id"]);

      await FirebaseFirestore.instance
          .collection(collectionName.groups)
          .doc(pId)
          .update({
        "users": currentUsers,
        "removedUsers": removedUsers,
      });

      // Send system message for removal
      String userName = appCtrl.user['name'];
      Encrypted encrypted =
      encryptFun("$userName removed ${value['name']} from the group");

      await FirebaseFirestore.instance
          .collection(collectionName.groups)
          .doc(pId)
          .collection(collectionName.chat)
          .add({
        'sender': appCtrl.user["id"],
        'senderName': userName,
        'receiver': currentUsers.map((e) => e["id"]).toList(),
        'content': encrypted.base64,
        'groupId': pId,
        'type': MessageType.messageType.name,
        "messageType": "sender",
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      onSendMessage(decrypt(encrypted.base64), MessageType.messageType);

      getPeerStatus();
      update();
    }
  }

  // removeUserFromGroup(value, snapshot) async {
  //   final groupDoc = await FirebaseFirestore.instance
  //       .collection(collectionName.groups)
  //       .doc(pId)
  //       .get();
  //
  //   if (groupDoc.exists) {
  //     List currentUsers = groupDoc.data()?["users"] ?? [];
  //
  //     // Fetch and normalize removedUsers as List<Map<String, dynamic>>
  //     dynamic rawRemoved = groupDoc.data()?["removedUsers"];
  //     List<Map<String, dynamic>> removedUsers = [];
  //
  //     if (rawRemoved is List) {
  //       removedUsers = List<Map<String, dynamic>>.from(rawRemoved);
  //     } else if (rawRemoved is Map) {
  //       removedUsers = rawRemoved.entries.map((entry) => {
  //         "id": entry.key,
  //         "chatId": entry.value,
  //       }).toList();
  //     }
  //
  //     // Get the current chat ID from user's chat collection
  //     List chats = await FirebaseFirestore.instance
  //         .collection(collectionName.users)
  //         .doc(value["id"])
  //         .collection(collectionName.chats)
  //         .where("groupId", isEqualTo: pId)
  //         .limit(1)
  //         .get()
  //         .then((snap) => snap.docs.map((e) => e.id).toList());
  //
  //     if (chats.isNotEmpty) {
  //       // Check if already stored, if not, add it
  //       if (!removedUsers.any((u) => u["id"] == value["id"])) {
  //         removedUsers.add({
  //           "id": value["id"],
  //           "chatId": chats.first,
  //         });
  //       }
  //     }
  //
  //     // Remove user from current user list
  //     currentUsers.removeWhere((e) => e["id"] == value["id"]);
  //
  //     await FirebaseFirestore.instance
  //         .collection(collectionName.groups)
  //         .doc(pId)
  //         .update({
  //       "users": currentUsers,
  //       "removedUsers": removedUsers,
  //     });
  //
  //     // Send system message for removal
  //     String userName = appCtrl.user['name'];
  //     Encrypted encrypted =
  //     encryptFun("$userName removed ${value['name']} from the group");
  //
  //     await FirebaseFirestore.instance
  //         .collection(collectionName.groups)
  //         .doc(pId)
  //         .collection(collectionName.chat)
  //         .add({
  //       'sender': appCtrl.user["id"],
  //       'senderName': userName,
  //       'receiver': currentUsers.map((e) => e["id"]).toList(),
  //       'content': encrypted.base64,
  //       'groupId': pId,
  //       'type': MessageType.messageType.name,
  //     "messageType": "sender",
  //       'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
  //     });
  //     onSendMessage(decrypt(encrypted.base64),MessageType.messageType);
  //
  //     getPeerStatus();
  //     update();
  //   }
  // }

  getTapPosition(TapDownDetails tapDownDetails) {
    RenderBox renderBox = Get.context!.findRenderObject() as RenderBox;
    update();
    tapPosition = renderBox.globalToLocal(tapDownDetails.globalPosition);
  }

  showContextMenu(context, value, snapshot) async {
    RenderObject? overlay = Overlay.of(context).context.findRenderObject();
    final result = await showMenu(
        color: appCtrl.appTheme.white,
        context: context,
        position: RelativeRect.fromRect(
          Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 10, 10),
          Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width,
              overlay.paintBounds.size.height),
        ),
        items: [
          _buildPopupMenuItem("Chat $pName", 0),
          _buildPopupMenuItem("Remove $pName", 1),
        ]);
    if (result == 0) {
      var data = {
        "uid": value["id"],
        "username": value["name"],
        "phoneNumber": value["phone"],
        "image": snapshot.data!.data()!["image"],
        "description": snapshot.data!.data()!["statusDesc"],
        "isRegister": true,
      };
      UserContactModel userContactModel = UserContactModel.fromJson(data);
      saveContact(userContactModel);
    } else {
      removeUserFromGroup(value, snapshot);
    }
  }

  PopupMenuItem _buildPopupMenuItem(String title, int position) {
    return PopupMenuItem(
      value: position,
      child: Row(children: [
        Text(title.toString().tr,
            style: AppCss.manropeMedium14.textColor(appCtrl.appTheme.darkText))
      ]),
    );
  }

  Widget searchTextField() {
    return TextField(
      controller: txtChatSearch,
      onChanged: (val) async {
        count = null;
        searchChatId = [];
        selectedIndexId = [];
        /* message.asMap().entries.forEach((e) {
          if (decryptMessage(e.value.data()["content"])
              .toLowerCase()
              .contains(val)) {
            if (!searchChatId.contains(e.key)) {
              searchChatId.add(e.key);
            } else {
              searchChatId.remove(e.key);
            }
          }
          update();
        });*/

        localMessage.asMap().entries.forEach((element) {
          element.value.message!.asMap().entries.forEach((e) {
            if (decryptMessage(e.value.content)
                .toString()
                .toLowerCase()
                .contains(txtChatSearch.text)) {
              if (!searchChatId.contains(e.value.docId)) {
                searchChatId.add(e.value.docId);
              } else {
                searchChatId.remove(e.value.docId);
              }
            }
          });
        });
      },

      //Display the keyboard when TextField is displayed
      cursorColor: appCtrl.appTheme.darkText,
      style: AppCss.manropeMedium14.textColor(appCtrl.appTheme.darkText),
      textInputAction: TextInputAction.search,
      //Specify the action button on the keyboard
      decoration: InputDecoration(
        //Style of TextField
        enabledBorder: UnderlineInputBorder(
          //Default TextField border
            borderSide: BorderSide(color: appCtrl.appTheme.darkText)),
        focusedBorder: UnderlineInputBorder(
          //Borders when a TextField is in focus
            borderSide: BorderSide(color: appCtrl.appTheme.darkText)),
        hintText: 'Search', //Text that is displayed when nothing is entered.
      ),
    );
  }

  onEmojiTap(emoji) {
    onSendMessage(emoji, MessageType.text);
  }

  deleteChat() async {
    Get.back();
    for (var c in multipleSelectedIndex) {
      int index = localMessage.indexWhere((element) {
        return element.time!.contains("-")
            ? element.time!.split("-")[0] == c['title']
            : element.time == c['title'];
      });

      int messageIndex = localMessage[index]
          .message!
          .indexWhere((element) => element.docId == c['docId']);

      if (messageIndex >= 0) {
        localMessage[index].message!.removeAt(messageIndex);
      }
      if (localMessage[index].message == null ||
          localMessage[index].message!.isEmpty) {
        localMessage.removeAt(index);
      }
    }

    if (deleteOption == "fromMe") {
      Get.back();
      selectedIndexId.asMap().entries.forEach((element) async {
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(appCtrl.user['id'])
            .collection(collectionName.groupMessage)
            .doc(pId)
            .collection(collectionName.chat)
            .doc(element.value)
            .delete();
      });
      await FirebaseFirestore.instance.runTransaction((transaction) async {});
      listScrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(appCtrl.user["id"])
          .collection(collectionName.groupMessage)
          .doc(pId)
          .collection(collectionName.chat)
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get()
          .then((value) {
        if (value.docs.isEmpty) {
          FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(appCtrl.user['id'])
              .collection(collectionName.chats)
              .where("groupId", isEqualTo: pId)
              .get()
              .then((value) {
            FirebaseFirestore.instance
                .collection(collectionName.users)
                .doc(appCtrl.user['id'])
                .collection(collectionName.chats)
                .doc(value.docs[0].id)
                .delete();
          });
        } else {
          FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(appCtrl.user['id'])
              .collection(collectionName.chats)
              .where("groupId", isEqualTo: pId)
              .get()
              .then((snapShot) {
            if (snapShot.docs.isNotEmpty) {
              FirebaseFirestore.instance
                  .collection(collectionName.users)
                  .doc(snapShot.docs[0].id)
                  .update({
                "updateStamp": DateTime.now().millisecondsSinceEpoch.toString(),
                "lastMessage": value.docs[0].data()["content"],
                "senderId": value.docs[0].data()["senderId"],
                "receiverId": value.docs[0].data()["receiverId"],
              });
            }
          });
        }
      });
      selectedIndexId = [];
      showPopUp = false;
      enableReactionPopup = false;
      update();
    } else {
      Get.back();
      List receiver = pData["groupData"]["users"] ?? [];
      receiver.asMap().entries.forEach(
            (user) async {
          selectedIndexId.asMap().entries.forEach((element) async {
            await FirebaseFirestore.instance
                .collection(collectionName.users)
                .doc(user.value['id'])
                .collection(collectionName.groupMessage)
                .doc(pId)
                .collection(collectionName.chat)
                .doc(element.value)
                .delete();
          });

          await FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(user.value['id'])
              .collection(collectionName.groupMessage)
              .doc(pId)
              .collection(collectionName.chat)
              .orderBy("timestamp", descending: true)
              .limit(1)
              .get()
              .then((value) {
            if (value.docs.isEmpty) {
              FirebaseFirestore.instance
                  .collection(collectionName.users)
                  .doc(user.value['id'])
                  .collection(collectionName.chats)
                  .where("groupId", isEqualTo: pId)
                  .get()
                  .then((value) {
                FirebaseFirestore.instance
                    .collection(collectionName.users)
                    .doc(user.value['id'])
                    .collection(collectionName.chats)
                    .doc(value.docs[0].id)
                    .delete();
              });
            } else {
              FirebaseFirestore.instance
                  .collection(collectionName.users)
                  .doc(user.value['id'])
                  .collection(collectionName.chats)
                  .where("groupId", isEqualTo: pId)
                  .get()
                  .then((snapShot) {
                if (snapShot.docs.isNotEmpty) {
                  FirebaseFirestore.instance
                      .collection(collectionName.users)
                      .doc(snapShot.docs[0].id)
                      .update({
                    "updateStamp": value.docs[0].data()['timestamp'],
                    "lastMessage": value.docs[0].data()["content"],
                    "messageType": value.docs[0].data()["messageType"],
                    "senderId": value.docs[0].data()["senderId"],
                    "receiverId": value.docs[0].data()["receiverId"],
                  });
                }
              });
            }
          });
          selectedIndexId = [];
          multipleSelectedIndex = [];
          showPopUp = false;
          enableReactionPopup = false;
          update();
        },
      );
      await FirebaseFirestore.instance.runTransaction((transaction) async {});
      listScrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      update();
    }
  }

  unLockChat() async {
    isLock = !isLock;
    isFilter = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    update();

    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(appCtrl.user["id"])
        .collection(collectionName.chats)
        .where("groupId", isEqualTo: pId)
        .limit(1)
        .get()
        .then(
          (value) async {
        if (value.docs.isNotEmpty) {
          FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(appCtrl.user["id"])
              .collection(collectionName.chats)
              .doc(value.docs[0].id)
              .update({"isLock": isLock});

          update();

          final message =
          Provider.of<RecentChatController>(Get.context!, listen: false);
          message.checkChatList(prefs);
        }
      },
    );
    update();
  }

  @override
  void onClose() {
    // Cancel subscriptions to prevent memory leaks
    messageSub?.cancel();
    log.log("GroupChatController: Subscriptions cancelled");
    super.onClose();
  }
}
