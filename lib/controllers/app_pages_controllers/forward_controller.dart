import 'dart:developer';

import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../../config.dart';
import '../../screens/app_screens/chat_message/chat_message_api.dart';

class ForwardController extends GetxController {
  List<MessageModel> selectedContent = [];
  bool isLoading = false;
  List forwardData = [];

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

    selectedContent = Get.arguments;
    update();
  }

  forwardDataTap(e) {
    String? chatId =
        e["chatId"] != null && e["chatId"] != "" ? e['chatId'] : null;
    String? groupId =
        e["groupId"] != null && e["groupId"] != "" ? e['groupId'] : null;
    log("CHAT :$chatId || $groupId");

    dynamic receiver = groupId != null
        ? e['receiverId']
        : e['senderId'] == appCtrl.user['id']
            ? e['receiverId']
            : e['senderId'];
    var d = {
      "id": chatId ?? groupId,
      "isChatId":chatId != null ? true : false,
      "receiver": receiver,
    };
    if (forwardData.where((element) => element['id'] == d['id']).isNotEmpty) {
      forwardData.removeWhere((element) => element['id'] == d['id']);
    } else {
      forwardData.add(d);
    }
    update();
  }

  isContain(e) {
    String? chatId =
        e["chatId"] != null && e["chatId"] != "" ? e['chatId'] : null;
    String? groupId =
        e["groupId"] != null && e["groupId"] != "" ? e['groupId'] : null;
    var d = {
      "id": chatId ?? groupId,
      "isChatId":chatId != null ? true : false,
    };
    print("ASASS :${forwardData}");
    return forwardData.where((element) => element['id'] == d['id']).isNotEmpty;
  }



  sendToAll() async {
    isLoading = true;
    log("forwardData::$forwardData");
    update();

    // Assume selectedContent has one MessageModel for simplicity
    if (selectedContent.isEmpty) {
      log("No content to forward");
      isLoading = false;
      update();
      Get.back();
      return;
    }

    // Take the first MessageModel (adjust if multiple messages are needed)
    final message = selectedContent.first;
    String content = message.content ?? "";
    MessageType messageType = getMessageTypeFromString(message.type!);
    log("selectedContent::$message, content::$content, messageType::$messageType");

    for (var element in forwardData.asMap().entries) {
      String id = element.value['id'];
      bool isChatId = element.value['isChatId'];

      if (isChatId) {
        String sendTo = element.value['receiver'];
        log("sendTo::$sendTo");

        // Save message for sender
        await ChatMessageApi().saveMessage(
          id,
          sendTo,
          content,
          messageType,
          DateTime.now().millisecondsSinceEpoch.toString(),
          appCtrl.user["id"],
        );

        // Save message for receiver
        await ChatMessageApi().saveMessage(
          id,
          sendTo,
          content,
          messageType,
          DateTime.now().millisecondsSinceEpoch.toString(),
          sendTo,
        );

        // Save in sender's user collection
        await FirebaseFirestore.instance.collection(collectionName.users).doc(sendTo).get().then((u) async {
          if (u.exists) {
            await ChatMessageApi().saveMessageInUserCollection(
              appCtrl.user["id"],
              sendTo,
              id,
              content,
              appCtrl.user["id"],
              u.data()!['name'],
              messageType,
            );
          }
        });

        // Save in receiver's user collection
        await ChatMessageApi().saveMessageInUserCollection(
          sendTo,
          sendTo,
          id,
          content,
          appCtrl.user["id"],
          appCtrl.user["name"],
          messageType,
        );

        // Send notification
        await FirebaseFirestore.instance.collection(collectionName.users).doc(sendTo).get().then((snap) async {
          if (snap.exists && snap.data()!["pushToken"] != "") {
            await firebaseCtrl.sendNotification(
              title: "New Message",
              msg: messageType == MessageType.text ? decrypt(content) : messageType.name,
              chatId: id,
              token: snap.data()!["pushToken"],
              dataTitle: appCtrl.user["name"],
              // userContact: appCtrl.user["name"],

              // messageId: DateTime.now().millisecondsSinceEpoch.toString(),
              // isGroup: "false",
            );
            log("Sent notification to $sendTo for chat $id");
          }
        });
      } else {
        // Group message
        await FirebaseFirestore.instance.collection(collectionName.groups).doc(id).get().then((v) async {
          if (v.exists) {
            List userList = v.data()!['receiver'] ?? v.data()!['users'];
            log("userList:${userList.length}");

            for (var user in userList.asMap().entries) {
              String userId = user.value["id"];
              String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

              // Save message in group chat
              await FirebaseFirestore.instance
                  .collection(collectionName.users)
                  .doc(userId)
                  .collection(collectionName.groupMessage)
                  .doc(id)
                  .collection(collectionName.chat)
                  .doc(timestamp)
                  .set({
                'sender': appCtrl.user["id"],
                'senderName': appCtrl.user["name"],
                'receiver': userList,
                'content': content,
                "groupId": id,
                'type': messageType.name,
                'messageType': "sender",
                "status": "",
                'timestamp': timestamp,
              });

              // Update group chat metadata
              await FirebaseFirestore.instance
                  .collection(collectionName.users)
                  .doc(userId)
                  .collection(collectionName.chats)
                  .where("groupId", isEqualTo: id)
                  .get()
                  .then((value) async {
                if (value.docs.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection(collectionName.users)
                      .doc(userId)
                      .collection(collectionName.chats)
                      .doc(value.docs[0].id)
                      .update({
                    "updateStamp": timestamp,
                    "lastMessage": content,
                    "senderId": appCtrl.user['id'],
                    "name": v.data()!["name"],
                    "groupImage": v.data()!['image'],
                  });

                  if (appCtrl.user["id"] != userId) {
                    await FirebaseFirestore.instance
                        .collection(collectionName.users)
                        .doc(userId)
                        .get()
                        .then((snap) async {
                      if (snap.exists && snap.data()!["pushToken"] != "") {
                        await firebaseCtrl.sendNotification(
                          title: "Group Message",
                          msg: groupMessageTypeCondition(messageType, decrypt(content)),
                          groupId: id,
                          token: snap.data()!["pushToken"],
                          dataTitle: v.data()!["name"],
                        );
                        log("Sent group notification to $userId for group $id");
                      }
                    });
                  }
                }
              });
            }
          }
        });
      }
    }

    await Future.delayed(Duration(seconds: 1));
    isLoading = false;
    Get.back();
    update();
  }
//   sendToAll() async {
//     isLoading = true;
// log("forwardData::${forwardData}");
//     update();
//     forwardData.asMap().entries.forEach(
//       (element) async {
//         log("selectedContent::${selectedContent}");
//        selectedContent.asMap().entries.map((mes) async{
// log("mes::$mes");
//          String content = mes.value.content!;
//          log("content::${content}");
//          MessageType messageType = getMessageTypeFromString(mes.value.type!);
//          String id = element.value['id'];
//          bool isChatId = element.value['isChatId'];
//          if (isChatId) {
//            String sendTo = element.value['receiver'];
// log("sendTo::$sendTo");
//            await ChatMessageApi()
//                .saveMessage(
//              id,
//              sendTo,
//              content,
//              messageType,
//              DateTime.now().millisecondsSinceEpoch.toString(),
//              appCtrl.user["id"],
//            )
//                .then((value) async {
//              await ChatMessageApi().saveMessage(
//                id,
//                sendTo,
//                content,
//                messageType,
//                DateTime.now().millisecondsSinceEpoch.toString(),
//                sendTo,
//              );
//            });
//
//            await FirebaseFirestore.instance.collection(collectionName.users).doc(sendTo).get().then((u) async{
//              if(u.exists){
//                await ChatMessageApi().saveMessageInUserCollection(appCtrl.user["id"], sendTo,
//                    id, content, appCtrl.user["id"], u.data()!['name'], messageType);
//              }
//            },);
//
//
//            await ChatMessageApi().saveMessageInUserCollection(sendTo, sendTo, id,
//                content, appCtrl.user["id"], appCtrl.user["name"], messageType);
//
//
//
//          } else {
//            await FirebaseFirestore.instance
//                .collection(collectionName.groups)
//                .doc(id)
//                .get()
//                .then(
//                  (v) async {
//                if (v.exists) {
//                  log("v.data()! :${v.data()!}");
//                  List userList = v.data()!['receiver']?? v.data()!['users'];
//                  log("userList :${userList.length}");
//                  userList.asMap().entries.forEach((element) async {
//                    await FirebaseFirestore.instance
//                        .collection(collectionName.users)
//                        .doc(element.value["id"])
//                        .collection(collectionName.groupMessage)
//                        .doc(id)
//                        .collection(collectionName.chat)
//                        .doc(DateTime.now().millisecondsSinceEpoch.toString())
//                        .set({
//                      'sender': appCtrl.user["id"],
//                      'senderName': appCtrl.user["name"],
//                      'receiver': userList,
//                      'content': content,
//                      "groupId": id,
//                      'type': messageType.name,
//                      'messageType': "sender",
//                      "status": "",
//                      'timestamp':
//                      DateTime.now().millisecondsSinceEpoch.toString(),
//                    });
//
//                    await FirebaseFirestore.instance
//                        .collection(collectionName.users)
//                        .doc(element.value)
//                        .collection(collectionName.chats)
//                        .where("groupId", isEqualTo: id)
//                        .get()
//                        .then((value) {
//                      if (value.docs.isNotEmpty) {
//                        FirebaseFirestore.instance
//                            .collection(collectionName.users)
//                            .doc(element.value["id"])
//                            .collection(collectionName.chats)
//                            .doc(value.docs[0].id)
//                            .update({
//                          "updateStamp":
//                          DateTime.now().millisecondsSinceEpoch.toString(),
//                          "lastMessage": content,
//                          "senderId": appCtrl.user['id'],
//                          "name": v.data()!["name"],
//                          "groupImage": v.data()!['image']
//                        });
//                        if (appCtrl.user["id"] != element.value["id"]) {
//                          FirebaseFirestore.instance
//                              .collection(collectionName.users)
//                              .doc(element.value["id"])
//                              .get()
//                              .then((snap) {
//                            if (snap.data()!["pushToken"] != "") {
//                              firebaseCtrl.sendNotification(
//                                  title: "Group Message",
//                                  msg: groupMessageTypeCondition(messageType,
//                                      decrypt(content)),
//                                  groupId: id,
//                                  token: snap.data()!["pushToken"],
//                                  dataTitle: v.data()!["name"]);
//                            }
//                          });
//                        }
//                      }
//                    });
//                  });
//                }
//              },
//            );
//          }
//        },);
//       },
//     );
//
//     await Future.delayed(Duration(seconds: 1));
//     isLoading = false;
//     Get.back();
//
//
//     update();
//   }
}
