import 'dart:convert' as encrypted;
import 'dart:developer';
import 'dart:io';
import 'package:encrypt/encrypt.dart';

import '../../config.dart';
import '../bottom_controllers/picker_controller.dart';
import '../common_controllers/all_permission_handler.dart';
import '../recent_chat_controller.dart';

class AddParticipantsController extends GetxController {
  List selectedContact = [];
  List existsUser = [];
  dynamic selectedData;
  List newContact = [];
  List contactList = [];
  final formKey = GlobalKey<FormState>();
  File? image;
  XFile? imageFile;
  bool isLoading = false, isGroup = true;
  dynamic user;
  int counter = 0;
  String imageUrl = "", groupId = "";
  TextEditingController txtGroupName = TextEditingController();
  final pickerCtrl = Get.isRegistered<PickerController>()
      ? Get.find<PickerController>()
      : Get.put(PickerController());
  final permissionHandelCtrl = Get.isRegistered<PermissionHandlerController>()
      ? Get.find<PermissionHandlerController>()
      : Get.put(PermissionHandlerController());

  //refresh and get contact
  Future<void> refreshContacts() async {
    isLoading = true;
    update();
    user = appCtrl.storage.read(session.user) ?? "";
    update();
  }

// Dismiss KEYBOARD
  void dismissKeyboard() {
    FocusScope.of(Get.context!).requestFocus(FocusNode());
  }

  addGroupBottomSheet() async {
    existsUser = [];
    log("ADD PARTICIPANTS1 $isGroup");
    
    // Проверяем, это звонок или группа
    dynamic args = Get.arguments ?? {};
    bool isCall = args['isCall'] ?? false;
    
    if (isCall) {
      // Если это звонок, просто возвращаем выбранных участников
      log("Adding participants to call");
      Get.back(result: selectedContact);
      return;
    }

    if (isGroup) {
      await FirebaseFirestore.instance
          .collection(collectionName.groups)
          .doc(groupId)
          .get()
          .then((value) async {
        if (value.exists) {
          List<dynamic> oldUsers = List.from(value.data()?["users"] ?? []);
          List<dynamic> removedUsers = List.from(value.data()?["removedUsers"] ?? []);

          // Filter only newly added contacts
          List newUsersToAdd = selectedContact
              .where((contact) => !oldUsers.any((oldUser) => oldUser['id'] == contact['id']))
              .toList();

          // Merge old + new
          existsUser = [...oldUsers, ...newUsersToAdd];
          log("Filtered new users: $newUsersToAdd");
          log("Final group users after adding: $existsUser");
          update();

          await FirebaseFirestore.instance
              .collection(collectionName.groups)
              .doc(groupId)
              .update({
            "users": existsUser,
          });

          final chatCtrl = Get.isRegistered<GroupChatMessageController>()
              ? Get.find<GroupChatMessageController>()
              : Get.put(GroupChatMessageController());

          chatCtrl.getPeerStatus();
          chatCtrl.userList = existsUser;
          chatCtrl.update();

          for (var i = 0; i < existsUser.length; i++) {
            if (chatCtrl.nameList != "") {
              chatCtrl.nameList = "${chatCtrl.nameList}, ${chatCtrl.pData["name"]}";
            } else {
              chatCtrl.nameList = chatCtrl.pData["name"];
            }
          }

          // Send system messages only to newly added users
          for (var user in newUsersToAdd) {
            String userName = appCtrl.user['name'];
            Encrypted encrypted = encryptFun("$userName added to the group");

            final messageData = {
              'sender': appCtrl.user["id"],
              'senderName': userName,
              'receiver': existsUser.map((e) => e["id"]).toList(),
              'content': encrypted.base64,
              'groupId': groupId,
              'type': MessageType.messageType.name,
              'messageType': "sender",
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            };

            await FirebaseFirestore.instance
                .collection(collectionName.groups)
                .doc(groupId)
                .collection(collectionName.chat)
                .add(messageData);

            // Check for removed user with existing chatId
            var removedUser = removedUsers.firstWhere(
                    (ru) => ru["id"] == user["id"],
                orElse: () => null);

            if (removedUser != null) {
              // User was previously removed, reuse chatId
              String chatId = removedUser["chatId"];

              await FirebaseFirestore.instance
                  .collection(collectionName.users)
                  .doc(user['id'])
                  .collection(collectionName.chats)
                  .doc(chatId)
                  .update({
                "isSeen": false,
                'receiverId': existsUser,
                "senderId": appCtrl.user["id"],
                'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
                "lastMessage": encrypted.base64,
                "messageType": "sender",
                "isGroup": true,
                "isBlock": false,
                "isBroadcast": false,
                "isBroadcastSender": false,
                "isOneToOne": false,
                "blockBy": "",
                "blockUserId": "",
                "name": chatCtrl.textNameController.text ?? "Group",
                "groupId": groupId,
                "groupRemoved": false,
                "updateStamp": DateTime.now().millisecondsSinceEpoch.toString()
              });

              // Remove from removedUsers
              removedUsers.removeWhere((u) => u["id"] == user["id"]);
            } else {
              // New user, create new chat entry
              await FirebaseFirestore.instance
                  .collection(collectionName.users)
                  .doc(user['id'])
                  .collection(collectionName.chats)
                  .add({
                "isSeen": false,
                'receiverId': existsUser,
                "senderId": appCtrl.user["id"],
                'chatId': "",
                'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
                "lastMessage": encrypted.base64,
                "messageType": "sender",
                "isGroup": true,
                "isBlock": false,
                "isBroadcast": false,
                "isBroadcastSender": false,
                "isOneToOne": false,
                "blockBy": "",
                "blockUserId": "",
                "name": chatCtrl.textNameController.text ?? "Group",
                "groupId": groupId,
                "updateStamp": DateTime.now().millisecondsSinceEpoch.toString()
              });
            }

            // Save updated removedUsers list
            await FirebaseFirestore.instance
                .collection(collectionName.groups)
                .doc(groupId)
                .update({
              "removedUsers": removedUsers,
            });

            log("encrypted.base64::${encrypted.base64}");
            final grpCtrl = Get.put(GroupChatMessageController());
            grpCtrl.onSendMessage(decrypt(encrypted.base64), MessageType.messageType);
          }

          chatCtrl.update();
          selectedContact = [];
          update();

          final RecentChatController recentChatController =
          Provider.of<RecentChatController>(Get.context!, listen: false);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          recentChatController.checkChatList(prefs);

          Get.back();
        }
      });
    }

    // Broadcast logic remains unchanged...
  }

  // addGroupBottomSheet() async {
  //   existsUser = [];
  //   log("ADD PARTICIPANTS1 $isGroup");
  //
  //   if (isGroup) {
  //     await FirebaseFirestore.instance
  //         .collection(collectionName.groups)
  //         .doc(groupId)
  //         .get()
  //         .then((value) async {
  //       if (value.exists) {
  //         List<dynamic> oldUsers = List.from(value.data()?["users"] ?? []);
  //
  //         // Filter selectedContact to only new users
  //         List newUsersToAdd = selectedContact
  //             .where((contact) =>
  //         !oldUsers.any((oldUser) => oldUser['id'] == contact['id']))
  //             .toList();
  //
  //         // Merge old users with new users
  //         existsUser = [...oldUsers, ...newUsersToAdd];
  //         log("Filtered new users: $newUsersToAdd");
  //         log("Final group users after adding: $existsUser");
  //         update();
  //
  //         await FirebaseFirestore.instance
  //             .collection(collectionName.groups)
  //             .doc(groupId)
  //             .update({"users": existsUser}).then((value) async {
  //           Get.back();
  //
  //           final chatCtrl = Get.isRegistered<GroupChatMessageController>()
  //               ? Get.find<GroupChatMessageController>()
  //               : Get.put(GroupChatMessageController());
  //
  //           chatCtrl.getPeerStatus();
  //           chatCtrl.userList = existsUser;
  //           chatCtrl.update();
  //
  //           for (var i = 0; i < existsUser.length; i++) {
  //             if (chatCtrl.nameList != "") {
  //               chatCtrl.nameList =
  //               "${chatCtrl.nameList}, ${chatCtrl.pData["name"]}";
  //             } else {
  //               chatCtrl.nameList = chatCtrl.pData["name"];
  //             }
  //           }
  //
  //           // Send system messages only to newly added users
  //           for (var user in newUsersToAdd) {
  //             String userName = appCtrl.user['name'];
  //             Encrypted encrypted =
  //             encryptFun("$userName added to the group");
  //
  //             final messageData = {
  //               'sender': appCtrl.user["id"],
  //               'senderName': userName,
  //               'receiver': existsUser,
  //               'content': encrypted.base64,
  //               'groupId': groupId,
  //               'type': MessageType.messageType.name,
  //               'messageType': "sender",
  //               'timestamp':
  //               DateTime.now().millisecondsSinceEpoch.toString(),
  //             };
  //
  //             await FirebaseFirestore.instance
  //                 .collection(collectionName.groups)
  //                 .doc(groupId)
  //                 .collection(collectionName.chat)
  //                 .add(messageData);
  //
  //             await FirebaseFirestore.instance
  //                 .collection(collectionName.users)
  //                 .doc(user['id'])
  //                 .collection(collectionName.chats)
  //                 .add({
  //               "isSeen": false,
  //               'receiverId': existsUser,
  //               "senderId": appCtrl.user["id"],
  //               'chatId': "",
  //               'timestamp':
  //               DateTime.now().millisecondsSinceEpoch.toString(),
  //               "lastMessage": encrypted.base64,
  //               "messageType": "sender",
  //               "isGroup": true,
  //               "isBlock": false,
  //               "isBroadcast": false,
  //               "isBroadcastSender": false,
  //               "isOneToOne": false,
  //               "blockBy": "",
  //               "blockUserId": "",
  //               "name": chatCtrl.textNameController.text ?? "Group",
  //               "groupId": groupId,
  //               "updateStamp":
  //               DateTime.now().millisecondsSinceEpoch.toString()
  //             });
  //             log("encrypted.base64::${encrypted.base64}");
  //             final grpCtrl = Get.put(GroupChatMessageController());
  //             grpCtrl.onSendMessage(decrypt(encrypted.base64), MessageType.messageType);
  //           }
  //
  //           chatCtrl.update();
  //           selectedContact = [];
  //           update();
  //
  //           final RecentChatController recentChatController =
  //           Provider.of<RecentChatController>(Get.context!, listen: false);
  //           SharedPreferences prefs = await SharedPreferences.getInstance();
  //           recentChatController.checkChatList(prefs);
  //         });
  //       }
  //     });
  //   }
  //
  //   // Broadcast logic remains unchanged...
  // }

  /* addGroupBottomSheet() async {
    existsUser = [];
    log("ADD PARTICIPANTS1 $isGroup");

    if (isGroup) {
      final groupDoc = await FirebaseFirestore.instance
          .collection(collectionName.groups)
          .doc(groupId)
          .get();

      if (groupDoc.exists) {
        List<dynamic> oldUsers = List.from(groupDoc.data()?["users"] ?? []);
        List<dynamic> removedUsers = List.from(groupDoc.data()?["removedUsers"] ?? []);

        List newUsersToAdd = selectedContact
            .where((contact) => !oldUsers.any((u) => u['id'] == contact['id']))
            .toList();

        existsUser = [...oldUsers, ...newUsersToAdd];
        update();

        await FirebaseFirestore.instance
            .collection(collectionName.groups)
            .doc(groupId)
            .update({
          "users": existsUser,
        });

        final chatCtrl = Get.isRegistered<GroupChatMessageController>()
            ? Get.find<GroupChatMessageController>()
            : Get.put(GroupChatMessageController());

        chatCtrl.getPeerStatus();
        chatCtrl.userList = existsUser;
        chatCtrl.update();

        for (var user in newUsersToAdd) {
          String userName = appCtrl.user['name'];
          Encrypted encrypted =
          encryptFun("$userName added ${user['name']} to the group");

          final messageData = {
            'sender': appCtrl.user["id"],
            'senderName': userName,
            'receiver': existsUser,
            'content': encrypted.base64,
            'groupId': groupId,
            'type': MessageType.messageType.name,
            'messageType': "sender",
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          };

          await FirebaseFirestore.instance
              .collection(collectionName.groups)
              .doc(groupId)
              .collection(collectionName.chat)
              .add(messageData);

          // Find if user was removed before
          String? reusedChatId;
          var removedUserData = removedUsers
              .firstWhereOrNull((e) => e['id'] == user['id']);
          reusedChatId = removedUserData?['chatId'];

          await FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(user['id'])
              .collection(collectionName.chats)
              .doc(reusedChatId ?? FirebaseFirestore.instance.collection("tmp").doc().id)
              .set({
            "isSeen": false,
            'receiverId': existsUser,
            "senderId": appCtrl.user["id"],
            'chatId': reusedChatId ?? "",
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            "lastMessage": encrypted.base64,
            "messageType": "system",
            "isGroup": true,
            "isBlock": false,
            "isBroadcast": false,
            "isBroadcastSender": false,
            "isOneToOne": false,
            "blockBy": "",
            "blockUserId": "",
            "name": chatCtrl.textNameController.text ?? "Group",
            "groupId": groupId,
            "updateStamp": DateTime.now().millisecondsSinceEpoch.toString()
          });

          // Remove from removedUsers once added back
          if (reusedChatId != null) {
            removedUsers.removeWhere((e) => e["id"] == user["id"]);
            await FirebaseFirestore.instance
                .collection(collectionName.groups)
                .doc(groupId)
                .update({
              "removedUsers": removedUsers,
            });
          }
        }

        chatCtrl.update();
        selectedContact = [];
        update();

        final RecentChatController recentChatController =
        Provider.of<RecentChatController>(Get.context!, listen: false);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        recentChatController.checkChatList(prefs);
      }
    }
  }*/

  //check chat available with contacts
  Future<List> checkChatAvailable() async {
    final user = appCtrl.storage.read(session.user);
    selectedContact.asMap().entries.forEach((e) async {
      log("e.value : ${e.value["chatId"]}");
      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(user["id"])
          .collection(collectionName.chats)
          .where("isOneToOne", isEqualTo: true)
          .get()
          .then((value) {
        if (value.docs.isNotEmpty) {
          value.docs.asMap().entries.forEach((element) {
            if (element.value.data()["senderId"] == user["id"] &&
                element.value.data()["receiverId"] == e.value["id"] ||
                element.value.data()["senderId"] == e.value["id"] &&
                    element.value.data()["receiverId"] == user["id"]) {
              e.value["chatId"] = element.value.data()["chatId"];
              update();
              if (!newContact.contains(e.value)) {
                newContact.add(e.value);
              }
            } else {
              e.value["chatId"] = null;
              if (!newContact.contains(e.value)) {
                newContact.add(e.value);
              }
            }
          });
        } else {
          e.value["chatId"] = null;
          if (!newContact.contains(e.value)) {
            newContact.add(e.value);
          }
        }
        update();
      });
    });

    return newContact;
  }

  //select user function
  selectUserTap(value) {
    var data = {
      "id": value.id,
      "name": value.name,
      "phone": value.phone,
      "image": value.image
    };
    bool exists = selectedContact.any((file) => file["phone"] == data["phone"]);
    log("exists : $exists");
    if (exists) {
      selectedContact.removeWhere(
            (element) => element["phone"] == data["phone"],
      );
    } else {
      /* if(selectedContact.length < appCtrl.usageControlsVal!.groupMembersLimit!) {

      }else{
        snackBarMessengers(message: "You can added only ${isGroup ? appCtrl.usageControlsVal!.groupMembersLimit! :appCtrl.usageControlsVal!.broadCastMembersLimit!} Members in the group");
      }*/
      selectedContact.add(data);
    }

    update();
  }

  //select user function
  alreadyExist(value) {
    log("PHONE : $value");
    var data = {
      "id": value["id"],
      "name": value["name"],
      "phone": value["phone"],
      "image": value["image"]
    };
    bool exists = selectedContact.any((file) => file["phone"] == data["phone"]);
    log("exists : $exists");
    if (exists) {
      selectedContact.removeWhere(
            (element) => element["phone"] == data["phone"],
      );
    } else {
      /* if(selectedContact.length < appCtrl.usageControlsVal!.groupMembersLimit!) {

      }else{
        snackBarMessengers(message: "You can added only ${isGroup ? appCtrl.usageControlsVal!.groupMembersLimit! :appCtrl.usageControlsVal!.broadCastMembersLimit!} Members in the group");
      }*/
      selectedContact.add(data);
    }

    update();
  }

  @override
  void onReady() {
// TODO: implement onReady
    var data = Get.arguments ?? "";
    existsUser = data["exitsUser"];
    groupId = data["groupId"];
    isGroup = data["isGroup"] ?? true;
    refreshContacts();
    log("ADD PARTICIPANTS $data");

    selectedContact = [];
    existsUser.asMap().forEach((key, value) {
      log("data : ${value["phone"]}");
      alreadyExist(value);
    });
    update();
    super.onReady();
  }
}
