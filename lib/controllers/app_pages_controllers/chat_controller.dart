import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:chatzy/controllers/common_controllers/contact_controller.dart';
import 'package:dartx/dartx_io.dart';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:encrypt/encrypt.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:swipe_to/swipe_to.dart';
import '../../config.dart';
import '../../screens/app_screens/chat_message/chat_message_api.dart';
import '../../screens/app_screens/chat_message/layouts/audio_recording_plugin.dart';
import '../../screens/app_screens/chat_message/layouts/chat_wall_paper.dart';
import '../../screens/app_screens/chat_message/layouts/delete_alert.dart';
import '../../screens/app_screens/chat_message/layouts/file_bottom_sheet.dart';
import '../../screens/app_screens/chat_message/layouts/forward_list.dart';
import '../../screens/app_screens/chat_message/layouts/receiver/receiver_message.dart';
import '../../screens/app_screens/chat_message/layouts/sender/sender_message.dart';
import '../../screens/app_screens/chat_message/layouts/single_clear_dialog.dart';
import '../../widgets/reaction_pop_up/emoji_picker_widget.dart';
import '../bottom_controllers/picker_controller.dart';
import '../common_controllers/all_permission_handler.dart';
import '../recent_chat_controller.dart';

class ChatController extends GetxController {
  String? pId,
      id,
      chatId,
      pName,
      groupId,
      imageUrl,
      peerNo,
      status,
      statusLastSeen,
      videoUrl,
      blockBy,
      audioUrl;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> allMessages = [];
  List<DateTimeChip> localMessage = [];
  StreamSubscription? messageSub;
  StreamSubscription? userDataSub;
  List message = [];
  dynamic pData, allData, userData;
  List<File> selectedImages = [];
  dynamic selectedWallpaper, businessData;
  UserContactModel? userContactModel;
  bool positionStreamStarted = false, isExpand = false;
  Duration? videoDuration, audioDuration;
  bool isUserAvailable = true, isUserSubscribe = false, isContactSearch = false;
  XFile? imageFile;
  XFile? videoFile;
  String? audioFile, wallPaperType, deleteOption;
  String selectedImage = "", backgroundImage = "";
  final picker = ImagePicker();
  File? selectedFile;
  File? image;
  File? video;
  int? count;
  bool isLoading = false, isLock = false;
  bool enableReactionPopup = false, isChatSearch = false;
  bool showPopUp = false;
  List<MessageModel> selectedContent = [];
  List selectedIndexId = [], multipleSelectedIndex = [];
  List clearChatId = [], searchChatId = [];
  String? selectedUser;
  RegisterContactDetail? forwardUser;
  bool _isForwarded = false;
  bool typing = false, isBlock = false;
  bool isShowSticker = false, isEmoji = false;

  final pickerCtrl = Get.isRegistered<PickerController>()
      ? Get.find<PickerController>()
      : Get.put(PickerController());
  final permissionHandelCtrl = Get.isRegistered<PermissionHandlerController>()
      ? Get.find<PermissionHandlerController>()
      : Get.put(PermissionHandlerController());

  TextEditingController textEditingController = TextEditingController();
  TextEditingController txtChatSearch = TextEditingController();
  TextEditingController searchText = TextEditingController();

  ScrollController listScrollController = ScrollController();
  FocusNode focusNode = FocusNode();
  late encrypt.Encrypter cryptor;
  final iv = encrypt.IV.fromLength(8);
  bool isFilter = false, isCallFilter = false;
  SharedPreferences? prefs;
  dynamic data;

  onTapDots() {
    isFilter = !isFilter;
    update();
  }

  onTapCallDots() {
    isCallFilter = !isCallFilter;
    update();
  }

  getAllDataLocally() async {
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(appCtrl.user["id"])
        .collection(collectionName.messages)
        .doc(chatId)
        .collection(collectionName.chat)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        allMessages = value.docs;
        update();
        log("allMessages ::: $allMessages");
        ChatMessageApi().getLocalMessage();
        update();
        isLoading = false;
        update();
      }
    });
    /*  if (data["allMessage"] != "") {
      allMessages = data["allMessage"];
      update();
      ChatMessageApi().getLocalMessage();
      update();
    }*/
    //  allMessages.add(value)
  }

  @override
  void onReady() {
    //  implement onReady
    selectedWallpaper =
        appCtrl.storage.read("backgroundImage") ?? eImageAssets.bg10;
    textEditingController.addListener(() {
      update();
    });
    isShowSticker = false;
    groupId = '';
    isLoading = true;
    imageUrl = '';
    userData = appCtrl.storage.read(session.user);
    data = Get.arguments;
    log("data ::$data");
    if (data == "No User") {
      isUserAvailable = false;
    } else {
      log("chatId::$chatId");
      chatId = data["chatId"];
      userContactModel = data["data"];
      pId = userContactModel?.uid??'';
      pName = userContactModel!.username;
      loadChatWallpaper(chatId!);
      //getAllDataLocally(data);
      isUserAvailable = true;
      update();
      getChatData();
    }
    update();

    super.onReady();
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
                audioVideoCallTap(false);
              }
            });
          } else {
            await permissionHandelCtrl
                .getCameraMicrophonePermissions()
                .then((value) {
              if (value == true) {
                audioVideoCallTap(true);
              }
            });
          }
        });
  }

  //audio and video call tap
  audioVideoCallTap(isVideoCall) async {
    log("pData::$pData");
    await ChatMessageApi()
        .audioAndVideoCallApi(toData: pData, isVideoCall: isVideoCall);
  }
  void loadChatWallpaper(String chatId) {
    selectedWallpaper = appCtrl.storage.read("backgroundImage_$chatId")?? eImageAssets.bg10;
    update();
  }
  //get chat data
  getChatData() async {
    log("chatId :::$chatId");
    if (chatId != "0") {
      messageSub = FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(appCtrl.user["id"])
          .collection(collectionName.messages)
          .doc(chatId)
          .collection(collectionName.chat)
          .snapshots()
          .listen((event) async {
        log("allMessages::${event.docs}");
        allMessages = event.docs;
        update();
        ChatMessageApi().getLocalMessage();
        isLoading = false;
        update();
      });

      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(appCtrl.user["id"])
          .collection(collectionName.messages)
          .doc(chatId)
          .get()
          .then(
            (value) {
          if (value.exists) {
            log("DDD:${value.data()}");
          }
        },
      );
      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(userData["id"])
          .collection(collectionName.chats)
          .where("chatId", isEqualTo: chatId)
          .get()
          .then((value) {
        allData = value.docs[0].data();
        isLock = allData['isLock'] ?? false;

        if (allData['backgroundImage'] != null &&
            allData['backgroundImage'] != "") {
          backgroundImage = allData['backgroundImage'];
        } else {
          backgroundImage = "";
        }
        update();
      });
      isLoading = false;
      update();
    } else {
      localMessage = [];
      allMessages = [];
      isLoading = false;
      update();
    }
    seenMessage();

    // Subscribe to real-time updates of user data
    userDataSub = FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(pId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        pData = snapshot.data();
        log("pData updated (real-time):::$pData");
        update();
      }
    });

    if (allData != null) {
      if (allData["backgroundImage"] != null ||
          allData["backgroundImage"] != "") {
        FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(userData["id"])
            .get()
            .then((value) {
          if (value.exists) {
            allData["backgroundImage"] = value.data()!["backgroundImage"];
          }
        });
      }
    } else {
      allData = {};
      allData["backgroundImage"] = "";
      allData["isBlock"] = false;
      isBlock = false;
    }
    update();
    if (data["message"] != null && data['message'] != "") {
      log("CHECKKKKK");
      if (data["isCallEnd"] != null) {
        onSendMessage(data["message"], MessageType.text);
      } else {
        log("CHECKKKKK::${data["message"]}");
        onSendMessage(
            data["message"].statusType == StatusType.text.name
                ? data["message"].statusText!
                : data["message"].image!,
            data["message"].statusType == StatusType.image.name
                ? MessageType.image
                : data["message"].statusType == StatusType.text.name
                ? MessageType.text
                : MessageType.video);
      }
    }

    log("FORWARD :${data["forwardMessage"]}");
    if (data["forwardMessage"] != null && data['forwardMessage'] != "") {
      List forwardList = data["forwardMessage"];
      for (var d in forwardList) {
        MessageModel messageModel = d;
        MessageType type = getMessageType(messageModel.type);
        onSendMessage(
          decryptMessage(messageModel.content!),
          type,
        );
      }
    }
  }

/*  getChatData() async {
    log("chatId :::$chatId");
    if (chatId != "0") {
      messageSub = FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(appCtrl.user["id"])
          .collection(collectionName.messages)
          .doc(chatId)
          .collection(collectionName.chat)
          .snapshots()
          .listen((event) async {
        allMessages = event.docs;
        update();

        ChatMessageApi().getLocalMessage();

        isLoading = false;
        update();
      });
      if (userData != null) {
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(userData["id"])
            .collection(collectionName.chats)
            .where("chatId", isEqualTo: chatId)
            .get()
            .then((value) {
          allData = value.docs[0].data();
          isLock = allData['isLock'] ?? false;
          if (allData['backgroundImage'] != null &&
              allData['backgroundImage'] != "") {
            backgroundImage = allData['backgroundImage'];
          } else {
            backgroundImage = "";
          }

          update();
        });
      }
      isLoading = false;
      update();
    } else {
      localMessage = [];
      allMessages = [];
      isLoading = false;
      update();
    }

    await FirebaseFirestore.instance
        .collection(collectionName.subscribeUser)
        .doc(pId)
        .get()
        .then((value) async {
      if (value.exists) {
        isUserSubscribe = value.data()!['status'];
        await FirebaseFirestore.instance
            .collection(collectionName.business)
            .doc(pId)
            .get()
            .then((v) {
          if (v.exists) {
            businessData = v.data();
          }
        });
      } else {
        isUserSubscribe = false;
      }

      update();
    });
    seenMessage();
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(pId)
        .get()
        .then((value) {
      pData = value.data();

      update();
    });
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(pId)
        .get()
        .then((value) {
      pData = value.data();

      update();
    });

    if (allData != null) {
      if (allData["backgroundImage"] != null ||
          allData["backgroundImage"] != "") {
        FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(userData["id"])
            .get()
            .then((value) {
          if (value.exists) {
            allData["backgroundImage"] = value.data()!["backgroundImage"];
          }
        });
      }
    } else {
      allData = {};
      allData["backgroundImage"] = "";
      allData["isBlock"] = false;
      isBlock = false;
    }

    update();

    if (data != null && data["message"] != null) {
      log("CHECKKKKK");
      if (data["isCallEnd"] != null) {
        onSendMessage(data["message"], MessageType.text);
      } else {
        onSendMessage(
            data["message"].statusType == StatusType.text.name
                ? data["message"].statusText!
                : data["message"].image!,
            data["message"].statusType == StatusType.image.name
                ? MessageType.image
                : data["message"].statusType == StatusType.text.name
                    ? MessageType.text
                    : MessageType.video);
      }
    }
    log("FORWARD :${data["forwardMessage"]}");
    if (data["forwardMessage"] != null && data['forwardMessage'] != "") {
      List forwardList = data["forwardMessage"];
      for (var d in forwardList) {
        MessageModel messageModel = d;
        MessageType type = getMessageType(messageModel.type);
        onSendMessage(
            decryptMessage(messageModel.content!),
            type,
        );
      }
    }
  }*/

  //audio and video call tap
  /*audioVideoCallTap(isVideoCall) async {
    log("pData : $pData");

    await ChatMessageApi()
        .audioAndVideoCallApi(toData: pData, isVideoCall: isVideoCall);
  }*/

  //update typing status
  setTyping() async {
    textEditingController.addListener(() {
      if (textEditingController.text.isNotEmpty) {
        firebaseCtrl.setTyping();
        typing = true;
      }
      if (textEditingController.text.isEmpty && typing == true) {
        firebaseCtrl.setIsActive();
        typing = false;
      }
    });
  }

  //seen all message
  seenMessage() async {
    if (allData != null) {
      if (allData['senderId'] != appCtrl.user['id']) {
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(appCtrl.user["id"])
            .collection(collectionName.messages)
            .doc(chatId)
            .collection(collectionName.chat)
            .where("receiver", isEqualTo: appCtrl.user["id"])
            .get()
            .then((value) {
          log("RECEIVER 1: ${value.docs.length}");
          value.docs.asMap().entries.forEach((element) async {
            await FirebaseFirestore.instance
                .collection(collectionName.users)
                .doc(appCtrl.user["id"])
                .collection(collectionName.messages)
                .doc(chatId)
                .collection(collectionName.chat)
                .doc(element.value.id)
                .update({"isSeen": true});
          });
        });
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(userData["id"])
            .collection(collectionName.chats)
            .where("chatId", isEqualTo: chatId)
            .get()
            .then((value) async {
          if (value.docs.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection(collectionName.users)
                .doc(userData["id"])
                .collection(collectionName.chats)
                .doc(value.docs[0].id)
                .update({"isSeen": true});
          }
        });

        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(pId)
            .collection(collectionName.messages)
            .doc(chatId)
            .collection(collectionName.chat)
            .where("receiver", isEqualTo: appCtrl.user["id"])
            .get()
            .then((value) {
          log("RECEIVER : ${value.docs.length}");
          value.docs.asMap().entries.forEach((element) async {
            await FirebaseFirestore.instance
                .collection(collectionName.users)
                .doc(pId)
                .collection(collectionName.messages)
                .doc(chatId)
                .collection(collectionName.chat)
                .doc(element.value.id)
                .update({"isSeen": true});
          });
        });
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(pId)
            .collection(collectionName.chats)
            .where("chatId", isEqualTo: chatId)
            .get()
            .then((value) async {
          if (value.docs.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection(collectionName.users)
                .doc(pId)
                .collection(collectionName.chats)
                .doc(value.docs[0].id)
                .update({"isSeen": true});
          }
        });
      }
    }
  }

  //share document
  documentShare({bool isAudio = false}) async {
    pickerCtrl.dismissKeyboard();
    Get.back();

    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      isLoading = true;
      update();
      Get.forceAppUpdate();
      File file = File(result.files.single.path.toString());
      String fileName =
          "${file.name}-${DateTime.now().millisecondsSinceEpoch.toString()}";
      log("file : $file");
      Reference reference = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = reference.putFile(file);
      TaskSnapshot snap = await uploadTask;
      String downloadUrl = await snap.ref.getDownloadURL();
      isLoading = true;
      log("MP3 ${result.files.single.path.toString()}");
      update();

      onSendMessage(
          "${result.files.single.name}-BREAK-$downloadUrl",
          result.files.single.path.toString().contains(".mp4")
              ? MessageType.video
              : result.files.single.path.toString().contains(".mp3")
              ? MessageType.audio
              : MessageType.doc);
    }
  }

  //location share
  Future locationShare() async {
    pickerCtrl.dismissKeyboard();
    Get.back();
    update();
    isLoading = true;
    var value = await permissionHandelCtrl.getCurrentPosition();

    await Future.delayed(DurationsClass.ms150);
    log("value getCurrentPosition :${value!.latitude}");
    log("value getCurrentPosition : $value");
    update();
    var locationString =
        'https://www.google.com/maps/search/?api=1&query=${value.latitude},${value.longitude}';
    isLoading = false;
    update();
    onSendMessage(locationString, MessageType.location);
  }

  //share media
  shareMedia(BuildContext context) {
    showModalBottomSheet(
        barrierColor: appCtrl.appTheme.trans,
        backgroundColor: appCtrl.appTheme.trans,
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.r25))),
        builder: (BuildContext context) {
          // return your layout

          return const FileBottomSheet();
        });
  }

  //block user
  blockUser() async {
    isBlock = !isBlock;
    log("isBlock : $isBlock");
    update();

    DateTime now = DateTime.now();
    String? newChatId =
    chatId == "0" ? now.microsecondsSinceEpoch.toString() : chatId;
    chatId = newChatId;
    update();

    if (allData["isBlock"] == true) {
      Encrypted encrypteded = encryptFun("You unblock this contact");
      String encrypted = encrypteded.base64;

      ChatMessageApi().saveMessage(
          newChatId,
          pId,
          encrypted,
          MessageType.messageType,
          DateTime.now().millisecondsSinceEpoch.toString(),
          userData["id"]);

      await ChatMessageApi().saveMessageInUserCollection(
        userData["id"],
        pId,
        newChatId,
        encrypted,
        isBlock: false,
        userData["id"],
        userData["name"],
        MessageType.messageType,
      );
    } else {
      Encrypted encrypteded = encryptFun("You block this contact");
      String encrypted = encrypteded.base64;

      ChatMessageApi().saveMessage(
          newChatId,
          pId,
          encrypted,
          MessageType.messageType,
          DateTime.now().millisecondsSinceEpoch.toString(),
          userData["id"]);

      await ChatMessageApi().saveMessageInUserCollection(
        userData["id"],
        pData["id"],
        newChatId,
        encrypted,
        isBlock: true,
        userData["id"],
        userData["name"],
        MessageType.messageType,
      );
    }
    update();

    getChatData();
  }

// UPLOAD SELECTED IMAGE TO FIREBASE
  Future uploadFile() async {
    imageFile = pickerCtrl.imageFile;
    update();
    isLoading = true;
    update();
    log("chat_con : $imageFile");
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref().child(fileName);
    var file = File(imageFile!.path);
    UploadTask uploadTask = reference.putFile(file);
    uploadTask.then((res) {
      isLoading = true;
      update();
      res.ref.getDownloadURL().then((downloadUrl) {
        imageUrl = downloadUrl;
        imageFile = null;
        log("imageUrl : $imageUrl");
        isLoading = false;
        update();
        onSendMessage(imageUrl!, MessageType.image);
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
    appCtrl.isLoading = true;
    appCtrl.update();
    log("singleChatCtrl::$imageFile");
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref().child(fileName);
    var file = File(imageFile.path);
    log("file::$imageFile");

    UploadTask uploadTask = reference.putFile(file);
    uploadTask.then((res) {
      log("uploadTask::$uploadTask");
      res.ref.getDownloadURL().then((downloadUrl) async {
        imageUrl = downloadUrl;
        appCtrl.isLoading = false;
        appCtrl.update();
        onSendMessage(imageUrl!, messageType);
        update();
      }, onError: (err) {
        appCtrl.isLoading = false;
        appCtrl.update();
        Fluttertoast.showToast(msg: 'Image is Not Valid');
      });
    });
  }

  //send video after recording or pick from media
  videoSend() async {
    videoFile = pickerCtrl.videoFile;
    log("videoFile : $videoFile");
    isLoading = true;
    update();
    const Duration(seconds: 2);
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref().child(fileName);
    var file = File(videoFile!.path);
    log("TASk File $file");
    UploadTask uploadTask = reference.putFile(file);
    log("uploadTast $uploadTask");
    uploadTask.then((res) {
      res.ref.getDownloadURL().then((downloadUrl) {
        videoUrl = downloadUrl;
        log("VideoURL $videoUrl");
        isLoading = false;
        update();
        onSendMessage(videoUrl!, MessageType.video);
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

  //pick up contact and share
  saveContactInChat() async {
    log("PREF ${appCtrl.pref}");
    PermissionStatus permissionStatus =
    await permissionHandelCtrl.getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      Get.back();
      Get.to(() => FetchContact(prefs: appCtrl.pref), arguments: true)!
          .then((value) async {
        if (value != null) {
          var contact = value;
          log("ccc : $contact");
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

  Future<void> checkPermission(String type, int index) async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    } else {
      audioRecording(type, index);
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
        log("file : $file");
        isLoading = true;
        update();
        String fileName =
            "${file.name}-${DateTime.now().millisecondsSinceEpoch.toString()}";
        Reference reference = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = reference.putFile(file);
        TaskSnapshot snap = await uploadTask;
        String downloadUrl = await snap.ref.getDownloadURL();
        log("audioFile : $downloadUrl");
        isLoading = false;
        update();
        onSendMessage(downloadUrl, MessageType.audio);
        log("audioFile : $downloadUrl");
      }
    });
  }

  /* void onSendMessage(String content, MessageType type,
      {isForward = false}) async {
    isLoading = true;
    update();
    isEmoji = false;
    Get.forceAppUpdate();
    Encrypted encrypteded = encryptFun(content);
    String encrypted = encrypteded.base64;
    newMessage = replyMessage;
    update();
    if (content.trim() != '') {
      textEditingController.clear();
      replyMessage = null;
      final now = DateTime.now();
      String? newChatId =
      chatId == "0" ? now.microsecondsSinceEpoch.toString() : chatId;
      chatId = newChatId;
      update();
      imageUrl = "";
      String time = DateTime.now().millisecondsSinceEpoch.toString();
      update();
      MessageModel messageModel = MessageModel(
          blockBy: allData != null ? allData["blockBy"] : "",
          blockUserId: allData != null ? allData["blockUserId"] : "",
          chatId: chatId,
          content: encrypted,
          docId: time,
          isBlock: false,
          isBroadcast: false,
          isForward: isForward,
          isFavourite: false,
          isSeen: false,
          messageType: "sender",
          receiver: pId,
          replyTo: newMessage != null ? newMessage!.content : "",
          replyType: newMessage != null ? newMessage!.type : "",
          sender: appCtrl.user["id"],
          timestamp: time,
          type: type.name);
      bool isEmpty =
          localMessage.where((element) => element.time == "Today").isEmpty;
      log("isEmpty :$isEmpty");

      int index = localMessage.indexWhere((element) => element.time == "Today");

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
      if (allData["isBlock"] != true) {
        await ChatMessageApi().saveMessageInUserCollection(userData["id"], pId,
            newChatId, encrypted, userData["id"], pName, type);
        await ChatMessageApi().saveMessageInUserCollection(pId, pId, newChatId,
            encrypted, userData["id"], userData["name"], type);
      }
      update();
      if (allData != null && allData != "") {
        if (allData["isBlock"] == true) {
          if (allData["blockUserId"] == pId) {
            ScaffoldMessenger.of(Get.context!).showSnackBar(
                SnackBar(content: Text(appFonts.unblockUser(pName))));
          } else {
            await ChatMessageApi()
                .saveMessage(
                newChatId, pId, encrypted, type, time, userData["id"],
                reply: newMessage != null ? newMessage!.content : "",
                isForward: isForward,
                replyType: newMessage != null
                    ? getMessageType(newMessage!.type)
                    : null)
                .then((snap) async {
              isLoading = false;
              update();
              Get.forceAppUpdate();
              await ChatMessageApi().saveMessageInUserCollection(
                  pData["id"],
                  userData["id"],
                  newChatId,
                  encrypted,
                  userData["id"],
                  pName,
                  type);
            }).then((value) {
              isLoading = false;
              update();
              Get.forceAppUpdate();
            });
          }
          isLoading = false;
          update();
        } else {
          update();
          Get.forceAppUpdate();
          log("DHRVI $type");
          await ChatMessageApi()
              .saveMessage(
            newChatId,
            pId,
            encrypted,
            type,
            time,
            userData["id"],
            reply: newMessage != null ? newMessage!.content : "",
            isForward: isForward,
            replyType:
            newMessage != null ? getMessageType(newMessage!.type) : null,
          )
              .then((value) async {
            await ChatMessageApi()
                .saveMessage(
              newChatId,
              pId,
              encrypted,
              type,
              time,
              pId,
              reply: newMessage != null ? newMessage!.content : "",
              replyType:
              newMessage != null ? getMessageType(newMessage!.type) : null,
            )
                .then((snap) async {
              isLoading = false;
              update();
              Get.forceAppUpdate();
            }).then((value) {
              isLoading = false;
              update();
              Get.forceAppUpdate();
            });
          });
        }
        isLoading = false;
        update();
        Get.forceAppUpdate();
      } else {
        isLoading = false;
        update();
        await ChatMessageApi().saveMessageInUserCollection(userData["id"], pId,
            newChatId, encrypted, userData["id"], pName, type);
        await ChatMessageApi().saveMessageInUserCollection(pId, pId, newChatId,
            encrypted, userData["id"], userData["name"], type);
        update();
        Get.forceAppUpdate();
        await ChatMessageApi()
            .saveMessage(
          newChatId,
          pId,
          encrypted,
          type,
          time,
          userData["id"],
          reply: newMessage != null ? newMessage!.content : "",
          isForward: isForward,
          replyType:
          newMessage != null ? getMessageType(newMessage!.type) : null,
        )
            .then((value) async {
          await ChatMessageApi()
              .saveMessage(
            newChatId,
            pId,
            encrypted,
            type,
            time,
            pId,
            reply: newMessage != null ? newMessage!.content : "",
            isForward: isForward,
            replyType:
            newMessage != null ? getMessageType(newMessage!.type) : null,
          )
              .then((snap) async {
            isLoading = false;
            update();
            Get.forceAppUpdate();
          }).then((value) {
            isLoading = false;
            update();
            Get.forceAppUpdate();
            getChatData();
          });
        });
      }
    }

    if (chatId != "0") {
      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(userData["id"])
          .collection(collectionName.chats)
          .where("chatId", isEqualTo: chatId)
          .get()
          .then((value) {
        allData = value.docs[0].data();

        update();
      });
    }
    log("chatId :: R$chatId");
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(appCtrl.user["id"])
        .collection(collectionName.messages)
        .doc(chatId)
        .collection(collectionName.chat)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        allMessages = value.docs;
        update();
        ChatMessageApi().getLocalMessage();
        update();
      }
    });
    log("allMessages : $allMessages");

    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(pId)
        .get()
        .then((value) {
      pData = value.data();
      log("pData :$pData");
      update();
    });
    newMessage = null;
    if (pData["pushToken"] != "") {
      firebaseCtrl.sendNotification(
          title: "Single Message",
          msg: messageTypeCondition(type, content),
          chatId: chatId,
          token: pData["pushToken"],
          pId: pId,
          pName: appCtrl.user["name"],
          userContactModel: userContactModel,
          image: userData["image"],
          dataTitle: appCtrl.user["name"]);
    }
    isLoading = false;
    if (allData == null) {
      getAllDataLocally();
    }
    prefs = await SharedPreferences.getInstance();
    update();
    final RecentChatController recentChatController =
    Provider.of<RecentChatController>(Get.context!, listen: false);
    recentChatController.checkChatList(prefs!);
    update();
    Get.forceAppUpdate();
  }*/
  // SEND MESSAGE CLICK
  void onSendMessage(String content, MessageType type) async {
    // isLoading = true;
    update();
    isEmoji = false;
    Get.forceAppUpdate();
    Encrypted encrypteded = encryptFun(content);
    String encrypted = encrypteded.base64;

    newMessage = replyMessage;
    if (content.trim() != '') {
      textEditingController.clear();
      replyMessage = null;
      final now = DateTime.now();
      String? newChatId =
      chatId == "0" ? now.microsecondsSinceEpoch.toString() : chatId;
      chatId = newChatId;

      update();
      imageUrl = "";
      String time = DateTime.now().millisecondsSinceEpoch.toString();
      update();
      MessageModel messageModel = MessageModel(
          blockBy: allData != null ? allData["blockBy"] : "",
          blockUserId: allData != null ? allData["blockUserId"] : "",
          chatId: chatId,
          content: encrypted,
          docId: time,
          isBlock: false,
          isBroadcast: false,
          isFavourite: false,
          isSeen: false,
          messageType: "sender",
          receiver: pId,
          replyTo: newMessage != null ? newMessage!.content : "",
          sender: appCtrl.user["id"],
          replyType: newMessage != null ? newMessage!.type : "",
          timestamp: time,
          type: type.name);
      bool isEmpty =
          localMessage.where((element) => element.time == "Today").isEmpty;
      log("isEmpty :$isEmpty");

      int index = localMessage.indexWhere((element) => element.time == "Today");

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
      if (allData["isBlock"] != true) {
        await ChatMessageApi().saveMessageInUserCollection(
          userData["id"],
          pId,
          chatId,
          encrypted,
          userData["id"],
          pName,
          type,
        );
        await ChatMessageApi().saveMessageInUserCollection(pId, pId, chatId,
            encrypted, userData["id"], userData["name"], type);
      }
      update();
      if (allData != null && allData != "") {
        if (allData["isBlock"] == true) {
          if (allData["blockUserId"] == pId) {
            ScaffoldMessenger.of(Get.context!).showSnackBar(
                SnackBar(content: Text(appFonts.unblockUser(pName))));
          } else {
            await ChatMessageApi()
                .saveMessage(
                newChatId, pId, encrypted, type, time, userData["id"],
                reply: newMessage != null ? newMessage!.content : "",
                replyType: newMessage != null
                    ? getMessageType(newMessage!.type)
                    : null)
                .then((snap) async {
              isLoading = false;
              update();

              Get.forceAppUpdate();
              await ChatMessageApi().saveMessageInUserCollection(
                  pData["id"],
                  userData["id"],
                  newChatId,
                  encrypted,
                  userData["id"],
                  pName,
                  type);
            }).then((value) {
              isLoading = false;
              update();
              Get.forceAppUpdate();
            });
          }
          isLoading = false;
          update();
        } else {
          update();
          Get.forceAppUpdate();
          await ChatMessageApi()
              .saveMessage(
              newChatId,
              pId,
              encrypted,
              type,
              DateTime.now().millisecondsSinceEpoch.toString(),
              userData["id"],
              reply: newMessage != null ? newMessage!.content : "",
              replyType: newMessage != null
                  ? getMessageType(newMessage!.type)
                  : null)
              .then((value) async {
            await ChatMessageApi()
                .saveMessage(newChatId, pId, encrypted, type,
                DateTime.now().millisecondsSinceEpoch.toString(), pId,
                reply: newMessage != null ? newMessage!.content : "",
                replyType: newMessage != null
                    ? getMessageType(newMessage!.type)
                    : null)
                .then((snap) async {
              isLoading = false;
              update();
              Get.forceAppUpdate();
            }).then((value) {
              isLoading = false;
              update();
              Get.forceAppUpdate();
            });
          });
        }
        isLoading = false;
        update();
        Get.forceAppUpdate();
      } else {
        isLoading = false;
        update();
        await ChatMessageApi().saveMessageInUserCollection(userData["id"], pId,
            newChatId, encrypted, userData["id"], pName, type);
        await ChatMessageApi().saveMessageInUserCollection(pId, pId, newChatId,
            encrypted, userData["id"], userData["name"], type);
        update();
        Get.forceAppUpdate();
        await ChatMessageApi()
            .saveMessage(
            newChatId,
            pId,
            encrypted,
            type,
            DateTime.now().millisecondsSinceEpoch.toString(),
            userData["id"],
            reply: newMessage != null ? newMessage!.content : "",
            replyType: newMessage != null
                ? getMessageType(newMessage!.type)
                : null)
            .then((value) async {
          await ChatMessageApi()
              .saveMessage(newChatId, pId, encrypted, type,
              DateTime.now().millisecondsSinceEpoch.toString(), pId,
              reply: newMessage != null ? newMessage!.content : "",
              replyType: newMessage != null
                  ? getMessageType(newMessage!.type)
                  : null)
              .then((snap) async {
            isLoading = false;
            update();
            Get.forceAppUpdate();
          }).then((value) {
            isLoading = false;
            update();
            Get.forceAppUpdate();
            getChatData();
          });
        });
      }
    }

    if (chatId != "0") {
      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(userData["id"])
          .collection(collectionName.chats)
          .where("chatId", isEqualTo: chatId)
          .get()
          .then((value) {
        allData = value.docs[0].data();

        update();
      });
    }
    log("chatId :: R$chatId");
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(appCtrl.user["id"])
        .collection(collectionName.messages)
        .doc(chatId)
        .collection(collectionName.chat)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        allMessages = value.docs;
        update();
        ChatMessageApi().getLocalMessage();
        update();
      }
    });
    log("allMessages : $allMessages");

    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(pId)
        .get()
        .then((value) {
      pData = value.data();

      update();
    });
    if (pData["pushToken"] != "") {
      firebaseCtrl.sendNotification(
          title: "Single Message",
          msg: messageTypeCondition(type, content),
          chatId: chatId,
          token: pData["pushToken"],
          pId: pId,
          pName: appCtrl.user["name"],
          userContactModel: userContactModel,
          image: userData["image"],
          dataTitle: appCtrl.user["name"]);


    }
    isLoading = false;
    if (allData == null) {
      getAllDataLocally();
    }
    update();
    Get.forceAppUpdate();
  }

  //delete chat layout
  buildPopupDialog() async {
    await showDialog(
        context: Get.context!, builder: (_) => const DeleteAlert());
  }

  wallPaperConfirmation(image) async {
    Get.generalDialog(
      pageBuilder: (context, anim1, anim2) {
        return ChatWallPaper(
          image: image,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
            position: Tween(begin: const Offset(0, -1), end: const Offset(0, 0))
                .animate(anim1),
            child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  Widget timeLayout() {
    return GetBuilder<ChatController>(builder: (chatCtrl) {
      return Column(
          children: localMessage.reversed.toList().asMap().entries.map((a) {
            List<MessageModel> newMessageList = a.value.message!.toList();

            return Column(children: [
              Text(
                  a.value.time!.contains("-other")
                      ? a.value.time!.split("-other")[0]
                      : a.value.time!,
                  style: AppCss.manropeMedium14
                      .textColor(appCtrl.appTheme.greyText))
                  .marginSymmetric(vertical: Insets.i5),
              GetBuilder<ChatController>(builder: (logic) {
                return ListView.builder(
                    shrinkWrap: true,
                    reverse: true,
                    controller: listScrollController,
                    itemCount: newMessageList.length,
                    itemBuilder: (context, index) {
                      return buildItem(
                          index,
                          newMessageList[index],
                          newMessageList[index].docId,
                          a.value.time!.contains("-other")
                              ? a.value.time!.split("-other")[0]
                              : a.value.time!,
                          newMessageList.first);
                    });
              })
            ]);
          }).toList());
    });
  }

  Widget buildItem(
      int index, MessageModel document, documentId, title, MessageModel swipe) {
    if (document.sender == userData["id"]) {
      return GetBuilder<ChatController>(builder: (chatCtrl) {
        return SwipeTo(
            onRightSwipe: (details) {
              Get.forceAppUpdate();
              log("DDD :${decryptMessage(document.content)} || $index");
              replyToMessage(document);
            },
            child: SenderMessage(
                document: document,
                index: index,
                docId: documentId,
                title: title)
                .inkWell(onTap: () {
              enableReactionPopup = false;
              showPopUp = false;
              selectedIndexId = [];
              update();
            }));
      });
    } else if (document.sender != userData["id"]) {
      // RECEIVER MESSAGE
      return document.type! == MessageType.messageType.name
          ? Container()
          : document.isBlock!
          ? Container()
          : SwipeTo(
        onRightSwipe: (details) {
          log("DDD s:$details");
          replyToMessage(document);
        },
        child: ReceiverMessage(
          document: document,
          index: index,
          docId: document.docId,
          title: title,
        ).inkWell(onTap: () {
          enableReactionPopup = false;
          showPopUp = false;
          selectedIndexId = [];
          update();
          log("enable : $enableReactionPopup");
        }),
      );
    } else {
      return Container();
    }
  }

  MessageModel? replyMessage;
  MessageModel? newMessage;
  VoidCallBack? onCancelReply;
  MessageModel? selectedMessage; // The selected message for replying

  void selectMessageForReply(MessageModel message) {
    selectedMessage = message; // Store the selected message for reply
    update(); // Notify UI to update if necessary
  }

  replyToMessage(MessageModel message) {
    replyMessage = message;
    update();
  }

  cancelReply() {
    replyMessage = null;
    update();
  }

  // ON BACK PRESS
  onBackPress() {
    appCtrl.isTyping = false;
    appCtrl.update();
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
        selectedContent = [];
        multipleSelectedIndex = [];
        selectedContent.add(message);
        multipleSelectedIndex.add(value);

        selectedIndexId.add(docId);
      }
      update();
    }
    update();
  }

  Widget searchTextField() {
    return TextField(
      controller: txtChatSearch,
      onChanged: (val) async {
        count = null;
        searchChatId = [];
        selectedIndexId = [];
        log("message : $message");
        localMessage.asMap().entries.forEach((element) {
          element.value.message!.asMap().entries.forEach((e) {
            if (decryptMessage(e.value.content)
                .toString()
                .toLowerCase()
                .contains(txtChatSearch.text)) {
              if (!searchChatId.contains(e.key)) {
                searchChatId.add(e.key);
              } else {
                searchChatId.remove(e.key);
              }
            }
          });
        });
        log("searchChatId :$searchChatId");
      },

      //Display the keyboard when TextField is displayed
      cursorColor: appCtrl.appTheme.borderColor,
      style: AppCss.manropeMedium14.textColor(appCtrl.appTheme.darkText),
      textInputAction: TextInputAction.search,
      //Specify the action button on the keyboard
      decoration: InputDecoration(
        //Style of TextField
        enabledBorder: UnderlineInputBorder(
          //Default TextField border
            borderSide: BorderSide(color: appCtrl.appTheme.borderColor)),
        focusedBorder: UnderlineInputBorder(
          //Borders when a TextField is in focus
            borderSide: BorderSide(color: appCtrl.appTheme.borderColor)),
        hintText: 'Search', //Text that is displayed when nothing is entered.
      ),
    );
  }

//clear dialog
  clearChatConfirmation() async {
    Get.generalDialog(
      pageBuilder: (context, anim1, anim2) {
        return const SingleClearDialog();
      },
    );
  }

  onEmojisBackPress() {
    textEditingController.text =
        textEditingController.text.characters.skipLast(1).toString();
    if (textEditingController.text.isEmpty) {
      isEmoji = false;
    }
    update();
  }

  showBottomSheet() => EmojiPickerWidget(
      controller: textEditingController,
      onSelected: (emoji) {
        textEditingController.text + emoji;
        isEmoji = true;
        update();
      });

  //ON SELECT EMOJI SEND TO CHAT
  onEmojiTap(emoji) {
    onSendMessage(emoji, MessageType.text);
  }

  Future<bool> onWillBackPress() {
    if (isShowSticker) {
      isShowSticker = false;
      update();
    } else {
      Get.back();
    }

    return Future.value(false);
  }

  deleteChat() async {
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

    // chatCtrl.localMessage[index].message![messageIndex].emoji = emoji;

    if (deleteOption == "fromMe") {
      Get.back();
      selectedIndexId.asMap().entries.forEach((element) async {
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(appCtrl.user['id'])
            .collection(collectionName.messages)
            .doc(chatId)
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
          .collection(collectionName.messages)
          .doc(chatId)
          .collection(collectionName.chat)
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get()
          .then((value) {
        if (value.docs.isEmpty) {
          FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(userData["id"])
              .collection(collectionName.chats)
              .where("chatId", isEqualTo: chatId)
              .get()
              .then((value) {
            FirebaseFirestore.instance
                .collection(collectionName.users)
                .doc(userData["id"])
                .collection(collectionName.chats)
                .doc(value.docs[0].id)
                .delete();
          });
        } else {
          FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(userData["id"])
              .collection(collectionName.chats)
              .where("chatId", isEqualTo: chatId)
              .get()
              .then((snapShot) {
            if (snapShot.docs.isNotEmpty) {
              FirebaseFirestore.instance
                  .collection('users')
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
      selectedIndexId.asMap().entries.forEach((element) async {
        log("EID :${element.value} || $pId $chatId    ");
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(appCtrl.user['id'])
            .collection(collectionName.messages)
            .doc(chatId)
            .collection(collectionName.chat)
            .doc(element.value)
            .delete();
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(pId)
            .collection(collectionName.messages)
            .doc(chatId)
            .collection(collectionName.chat)
            .doc(element.value)
            .delete();
      });
      await FirebaseFirestore.instance.runTransaction((transaction) async {});
      listScrollController.animateTo(0.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
/*
      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(pId)
          .collection(collectionName.messages)
          .doc(chatId)
          .collection(collectionName.chat)
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get()
          .then((value) {
        if (value.docs.isEmpty) {
          FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(pId)
              .collection(collectionName.chats)
              .where("chatId", isEqualTo: chatId)
              .get()
              .then((value) {
            FirebaseFirestore.instance
                .collection(collectionName.users)
                .doc(pId)
                .collection(collectionName.chats)
                .doc(value.docs[0].id)
                .delete();
          });
        } else {
          FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(pId)
              .collection(collectionName.chats)
              .where("chatId", isEqualTo: chatId)
              .get()
              .then((snapShot) {
            if (snapShot.docs.isNotEmpty) {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapShot.docs[0].id)
                  .update({
                "updateStamp": DateTime.now().millisecondsSinceEpoch.toString(),
                "lastMessage": value.docs[0].data()["content"],
                "senderId": value.docs[0].data()["senderId"],
                'sender': {
                  "id": value.docs[0].data()["sender"]['id'],
                  "name": value.docs[0].data()["sender"]['name'],
                  "image": value.docs[0].data()["sender"]["image"]
                },
                "receiverId": value.docs[0].data()["receiverId"],
                "receiver": {
                  "id": value.docs[0].data()["receiver"]["id"],
                  "name": value.docs[0].data()["receiver"]["name"],
                  "image": value.docs[0].data()["receiver"]["image"]
                }
              });
            }
          });
        }
      });*/
      selectedIndexId = [];
      showPopUp = false;
      enableReactionPopup = false;
      getAllDataLocally();
      update();
    }
  }

  forwardMessage() async {
    log("selectedContent:$selectedContent");
    Get.toNamed(routeName.forwardList,arguments: selectedContent)!.then((value) {
      selectedIndexId =[];
      update();
    },);
  }

  unLockChat() async {
    isLock = !isLock;
    isFilter = false;
    prefs = await SharedPreferences.getInstance();
    update();
    log("chatId:E${appCtrl.user["id"]}");
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(appCtrl.user["id"])
        .collection(collectionName.chats)
        .where("chatId", isEqualTo: chatId)
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
          message.checkChatList(prefs!);
        }
      },
    );
    update();
  }

  @override
  void onClose() {
    // Cancel subscriptions to prevent memory leaks
    messageSub?.cancel();
    userDataSub?.cancel();
    log("ChatController: Subscriptions cancelled");
    super.onClose();
  }
}
