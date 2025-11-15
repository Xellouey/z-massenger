import 'dart:developer' as log;
import 'package:chatzy/models/call_model.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';

class ChatMessageApi {
  Future saveMessage(
      newChatId, pId, encrypted, MessageType type, dateTime, senderId,
      {isBlock = false,
      isSeen = false,
      isBroadcast = false,
      blockBy = "",
      blockUserId = "",
      reply,
      MessageType? replyType,
      isForward = false}) async {
    log.log("SAVE :$replyType");
    dynamic userData = appCtrl.storage.read(session.user);
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(senderId)
        .collection(collectionName.messages)
        .doc(newChatId)
        .collection(collectionName.chat)
        .doc(dateTime)
        .set({
      'sender': userData["id"],
      'receiver': pId,
      'content': encrypted,
      "chatId": newChatId,
      'type': type.name,
      'messageType': "sender",
      "isBlock": isBlock,
      "isSeen": isSeen,
      "isBroadcast": isBroadcast,
      "blockBy": blockBy,
      "blockUserId": blockUserId,
      'timestamp': dateTime,
      "replyTo": reply,
      "replyType": replyType?.name,
      "isForward": isForward
    }, SetOptions(merge: true));
  }

  //save message in user
  saveMessageInUserCollection(
      id, receiverId, newChatId, content, senderId, userName, MessageType type,
      {isBlock = false, isBroadcast = false}) async {
    final chatCtrl = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());

    // FIXED: Search by participants instead of chatId to prevent duplicates
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(id)
        .collection(collectionName.chats)
        .where("isOneToOne", isEqualTo: true)
        .get()
        .then((value) async {

      // Find existing chat with this user by checking participants
      var existingChat = value.docs.where((doc) {
        var data = doc.data();
        // Check if participants match (in any order)
        return (data["senderId"] == receiverId || data["receiverId"] == receiverId) &&
               (data["senderId"] == senderId || data["receiverId"] == senderId);
      }).toList();

      if (existingChat.isNotEmpty) {
        // UPDATE existing chat
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(id)
            .collection(collectionName.chats)
            .doc(existingChat[0].id)
            .update({
          "updateStamp": DateTime.now().millisecondsSinceEpoch.toString(),
          "lastMessage": content,
          "senderId": senderId,
          "messageType": type.name,
          "chatId": newChatId,
          "isSeen": false,
          "isGroup": false,
          "name": userName,
          "isBlock": isBlock ?? false,
          "isOneToOne": true,
          "isBroadcast": isBroadcast,
          "blockBy": isBlock ? id : "",
          "blockUserId": isBlock ? receiverId : "",
          "receiverId": receiverId,
          "type": type.name
        }).then((value) {
          chatCtrl.textEditingController.text = "";
          chatCtrl.update();
        });
      } else {
        // CREATE new chat only if not found
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(id)
            .collection(collectionName.chats)
            .add({
          "updateStamp": DateTime.now().millisecondsSinceEpoch.toString(),
          "lastMessage": content,
          "senderId": senderId,
          "isSeen": false,
          "isGroup": false,
          "chatId": newChatId,
          "isBlock": isBlock ?? false,
          "isOneToOne": true,
          "name": userName,
          "isBroadcast": isBroadcast,
          "blockBy": isBlock ? id : "",
          "blockUserId": isBlock ? receiverId : "",
          "receiverId": receiverId,
          "type": type.name
        }).then((value) {
          chatCtrl.textEditingController.text = "";
          chatCtrl.update();
        });
      }
    }).then((value) {
      chatCtrl.isLoading = false;
      chatCtrl.update();
      Get.forceAppUpdate();
    });
  }

  //save group data
  saveGroupData(id, groupId, content, pData, type,groupImage) async {
    var user = appCtrl.storage.read(session.user);
    List receiver = pData["groupData"]["users"];
    receiver.asMap().entries.forEach((element) async {
      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(element.value["id"])
          .collection(collectionName.chats)
          .where("groupId", isEqualTo: groupId)
          .get()
          .then((value) {
        if (value.docs.isNotEmpty) {
          FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(element.value["id"])
              .collection(collectionName.chats)
              .doc(value.docs[0].id)
              .update({
            "updateStamp": DateTime.now().millisecondsSinceEpoch.toString(),
            "lastMessage": content,
            "senderId": user["id"],
            "name": pData["groupData"]["name"],
            "groupImage": groupImage
          });
          if (user["id"] != element.value["id"]) {
            FirebaseFirestore.instance
                .collection(collectionName.users)
                .doc(element.value["id"])
                .get()
                .then((snap) {
              if (snap.data()!["pushToken"] != "") {
                firebaseCtrl.sendNotification(
                    title: "Group Message",
                    msg: groupMessageTypeCondition(type, decrypt(content)),
                    groupId: groupId,
                    token: snap.data()!["pushToken"],
                    dataTitle: pData["groupData"]["name"]);
              }
            });
          }
        }
      });
    });
  }

  //audio and video call api
  audioAndVideoCallApi({toData, isVideoCall}) async {
    try {
      var userData = appCtrl.storage.read(session.user);
      log.log("📞 [CHAT] Starting call initiation from chat screen");
      log.log("toData['id']::${toData}");

      // Get fresh receiver data from Firestore
      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(toData['id'])
          .get()
          .then((value) {
        log.log("TODAT :%${value.data()}");
        toData = value.data();
      });

      // Проверка: нельзя звонить самому себе
      if (userData["id"] == toData["id"]) {
        log.log("❌ ERROR: Cannot call yourself!");
        Fluttertoast.showToast(msg: appFonts.cannotCallYourself.tr);
        return;
      }

      log.log("✅ Self-call check passed");

      // Get fresh pushToken from Firestore (not cached)
      String? freshReceiverToken;
      try {
        final receiverDoc = await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(toData["id"])
            .get();

        if (receiverDoc.exists && receiverDoc.data() != null) {
          freshReceiverToken = receiverDoc.data()!["pushToken"];
          log.log("✅ Fresh receiver token obtained: ${freshReceiverToken != null}");
        } else {
          log.log("⚠️ Receiver document not found, using cached token");
          freshReceiverToken = toData["pushToken"];
        }
      } catch (e) {
        log.log("❌ ERROR getting fresh receiver token: $e");
        freshReceiverToken = toData["pushToken"]; // Fallback to cached
      }

      int timestamp = DateTime.now().millisecondsSinceEpoch;

      Map<String, dynamic>? response =
          await firebaseCtrl.getAgoraTokenAndChannelName();

      log.log("response userData:$userData");
      log.log("response toData:$toData");

      if (response != null) {
        String channelId = response["channelName"];
        String token = response["agoraToken"];

        log.log("✅ Agora token and channel obtained");
        log.log("   Channel: $channelId");
        log.log("   Token length: ${token.length}");

        Call call = Call(
            timestamp: timestamp,
            callerId: userData["id"],
            callerName: userData["name"],
            callerPic: userData["image"],
            receiverId: toData["id"],
            receiverName: toData["name"],
            receiverPic: toData["image"],
            callerToken: userData["pushToken"],
            receiverToken: freshReceiverToken ?? toData["pushToken"],
            channelId: channelId,
            isVideoCall: isVideoCall,
            agoraToken: token,
            receiver: null);

        log.log("call.receiverId::${call.callerPic}///${toData["id"]}");

        // Create both Firestore call records in parallel for speed
        try {
          await Future.wait([
            // Caller's call record
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call.callerId)
                .collection(collectionName.calling)
                .add({
              "timestamp": timestamp,
              "callerId": userData["id"],
              "callerName": userData["name"],
              "callerPic": userData["image"],
              "receiverId": toData["id"],
              "receiverName": toData["name"],
              "receiverPic": toData["image"],
              "callerToken": userData["pushToken"],
              "receiverToken": freshReceiverToken ?? toData["pushToken"],
              "hasDialled": true,
              "channelId": response['channelName'],
              "isVideoCall": isVideoCall,
              "agoraToken": token,
            }),
            // Receiver's call record
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call.receiverId)
                .collection(collectionName.calling)
                .add({
              "timestamp": timestamp,
              "callerId": userData["id"],
              "callerName": userData["name"],
              "callerPic": userData["image"],
              "receiverId": toData["id"],
              "receiverName": toData["name"],
              "receiverPic": toData["image"],
              "callerToken": userData["pushToken"],
              "receiverToken": freshReceiverToken ?? toData["pushToken"],
              "hasDialled": false,
              "channelId": response['channelName'],
              "isVideoCall": isVideoCall,
              "agoraToken": token,
            }),
          ]);

          log.log("✅ Call records created in Firestore for both users");

          Get.back();
          call.hasDialled = true;

          // Send notification with fresh token
          if (freshReceiverToken != null && freshReceiverToken.isNotEmpty) {
            try {
              if (isVideoCall == false) {
                await firebaseCtrl.sendNotification(
                    notificationType: 'call',
                    title: "Входящий аудиозвонок...",
                    msg: "${call.callerName} звонит!",
                    token: freshReceiverToken,
                    pName: call.callerName,
                    image: userData["image"],
                    dataTitle: call.callerName);
                log.log("✅ Audio call notification sent successfully");

                var data = {
                  "channelName": call.channelId,
                  "call": call,
                  "token": response["agoraToken"]
                };

                Get.toNamed(routeName.audioCall, arguments: data);
              } else {
                await firebaseCtrl.sendNotification(
                    notificationType: 'call',
                    title: "Входящий видеозвонок...",
                    msg: "${call.callerName} звонит!",
                    token: freshReceiverToken,
                    pName: call.callerName,
                    image: userData["image"],
                    dataTitle: call.callerName);
                log.log("✅ Video call notification sent successfully");
                log.log("call.channelId : ${call.channelId}");

                var data = {
                  "channelName": call.channelId,
                  "call": call,
                  "token": response["agoraToken"]
                };

                Get.toNamed(routeName.videoCall, arguments: data);
              }
            } catch (notifError) {
              log.log("❌ ERROR sending notification: $notifError");
              // Still open call screen even if notification fails
              var data = {
                "channelName": call.channelId,
                "call": call,
                "token": response["agoraToken"]
              };
              Get.toNamed(isVideoCall ? routeName.videoCall : routeName.audioCall, arguments: data);
            }
          } else {
            log.log("⚠️ Skipping notification send - no valid receiver token");
            Fluttertoast.showToast(msg: "Звонок инициирован, но уведомление не отправлено");
            // Still open call screen
            var data = {
              "channelName": call.channelId,
              "call": call,
              "token": response["agoraToken"]
            };
            Get.toNamed(isVideoCall ? routeName.videoCall : routeName.audioCall, arguments: data);
          }
        } catch (firestoreError) {
          log.log("❌ ERROR creating Firestore call records: $firestoreError");
          Fluttertoast.showToast(msg: "Ошибка при создании записи звонка");
        }

      } else {
        log.log("❌ Failed to get Agora token/channel");
        Fluttertoast.showToast(msg: "Не удалось позвонить");
      }
    } on FirebaseException catch (e) {
      // Caught an exception from Firebase.
      log.log("❌ Firebase exception in audioAndVideoCallApi: '${e.code}': ${e.message}");
      Fluttertoast.showToast(msg: "Ошибка Firebase при звонке");
    } catch (e, stackTrace) {
      log.log("❌ Unexpected error in audioAndVideoCallApi: $e");
      log.log("Stack trace: $stackTrace");
      Fluttertoast.showToast(msg: "Неожиданная ошибка при звонке");
    }
  }

  getMessageAsPerDate(snapshot) {
    final chatCtrl = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());
    List<QueryDocumentSnapshot<Object?>> message = (snapshot.data!).docs;
    List reveredList = message.reversed.toList();
    List<QueryDocumentSnapshot<Object?>> todayMessage = [];
    List<QueryDocumentSnapshot<Object?>> yesterdayMessage = [];
    List<QueryDocumentSnapshot<Object?>> newMessageList = [];
    reveredList.asMap().entries.forEach((element) {
      if (getDate(element.value.id) == "Today") {
        bool isExist = chatCtrl.message
            .where((element) => element["title"].toString().contains("Today"))
            .isNotEmpty;
        if (isExist) {
          if (!todayMessage.contains(element.value)) {
            todayMessage.add(element.value);
            int index = chatCtrl.message.indexWhere(
                (element) => element["title"].toString().contains("Today"));
            chatCtrl.message[index]["message"] = todayMessage;
          }
        } else {
          if (!todayMessage.contains(element.value)) {
            todayMessage.add(element.value);
            var data = {
              "title": getDate(element.value.id),
              "message": todayMessage
            };

            chatCtrl.message = [data];
          }
        }
      }
      if (getDate(element.value.id) == "Yesterday") {
        bool isExist = chatCtrl.message
            .where((element) => element["title"] == "Yesterday")
            .isNotEmpty;

        if (isExist) {
          if (!yesterdayMessage.contains(element.value)) {
            yesterdayMessage.add(element.value);
            int index = chatCtrl.message
                .indexWhere((element) => element["title"] == "Yesterday");
            chatCtrl.message[index]["message"] = yesterdayMessage;
          }
        } else {
          if (!yesterdayMessage.contains(element.value)) {
            yesterdayMessage.add(element.value);
            var data = {
              "title":
                  "${getDate(element.value.id)} ${DateFormat("HH:mma").format(DateTime.parse(DateTime.fromMillisecondsSinceEpoch(int.parse(element.value.id)).toString()))}",
              "message": yesterdayMessage
            };

            if (chatCtrl.message.isNotEmpty) {
              chatCtrl.message.add(data);
            } else {
              chatCtrl.message = [data];
            }
          }
        }
      }
      if (getDate(element.value.id) != "Yesterday" &&
          getDate(element.value.id) != "Today") {
        bool isExist = chatCtrl.message
            .where((element) => element["title"].contains("-other"))
            .isNotEmpty;

        if (isExist) {
          if (!newMessageList.contains(element.value)) {
            newMessageList.add(element.value);
            int index = chatCtrl.message
                .indexWhere((element) => element["title"].contains("-other"));
            chatCtrl.message[index]["message"] = newMessageList;
          }
        } else {
          if (!newMessageList.contains(element.value)) {
            newMessageList.add(element.value);
            var data = {
              "title": getDate(element.value.id),
              "message": newMessageList
            };

            if (chatCtrl.message.isNotEmpty) {
              chatCtrl.message.add(data);
            } else {
              chatCtrl.message = [data];
            }
          }
        }
      }
    });
  }

  getLocalMessage() {
    final chatCtrl = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());
    List<QueryDocumentSnapshot<Object?>> message = chatCtrl.allMessages;
    List reveredList = message.reversed.toList();
    chatCtrl.localMessage = [];

    reveredList.asMap().entries.forEach((element) {
      MessageModel messageModel = MessageModel(
          replyTo: element.value.data()["replyTo"],
          replyType: element.value.data()["replyType"],
          blockBy: element.value.data()["blockBy"],
          blockUserId: element.value.data()["blockUserId"],
          chatId: element.value.data()["chatId"],
          content: element.value.data()["content"],
          docId: element.value.id,
          emoji: element.value.data()["emoji"],
          favouriteId: element.value.data()["favouriteId"],
          isBlock: element.value.data()["isBlock"],
          isBroadcast: element.value.data()["isBroadcast"],
          isFavourite: element.value.data()["isFavourite"],
          isSeen: element.value.data()["isSeen"],
          messageType: element.value.data()["messageType"],
          receiver: element.value.data()["receiver"],
          sender: element.value.data()["sender"],
          emojiList: element.value.data()["emojiList"],
          timestamp: element.value.data()["timestamp"],
          type: element.value.data()["type"]);
      if (getDate(element.value.id) == "Today") {
        bool isEmpty = chatCtrl.localMessage
            .where((element) => element.time == "Today")
            .isEmpty;
        if (isEmpty) {
          List<MessageModel>? message = [];
          if (message.isNotEmpty) {
            message.add(MessageModel.fromJson(element.value.data()));
            message[0].docId = element.value.id;
          } else {
            message = [MessageModel.fromJson(element.value.data())];
            message[0].docId = element.value.id;
          }
          DateTimeChip dateTimeChip =
              DateTimeChip(time: getDate(element.value.id), message: message);
          chatCtrl.localMessage.add(dateTimeChip);
        } else {
          int index = chatCtrl.localMessage
              .indexWhere((element) => element.time == "Today");

          if (!chatCtrl.localMessage[index].message!.contains(messageModel)) {
            chatCtrl.localMessage[index].message!.add(messageModel);
          }
        }
      }

      if (getDate(element.value.id) == "Yesterday") {
        bool isEmpty = chatCtrl.localMessage
            .where((element) => element.time == "Yesterday")
            .isEmpty;
        if (isEmpty) {
          List<MessageModel>? message = [];
          if (message.isNotEmpty) {
            message.add(MessageModel.fromJson(element.value.data()));
            message[0].docId = element.value.id;
          } else {
            message = [MessageModel.fromJson(element.value.data())];
            message[0].docId = element.value.id;
          }
          DateTimeChip dateTimeChip =
              DateTimeChip(time: getDate(element.value.id), message: message);
          chatCtrl.localMessage.add(dateTimeChip);
        } else {
          int index = chatCtrl.localMessage
              .indexWhere((element) => element.time == "Yesterday");

          if (!chatCtrl.localMessage[index].message!.contains(messageModel)) {
            chatCtrl.localMessage[index].message!.add(messageModel);
          }
        }
      }

      if (getDate(element.value.id).contains("-other")) {
        bool isEmpty = chatCtrl.localMessage
            .where((element) => element.time!.contains("-other"))
            .isEmpty;
        if (isEmpty) {
          List<MessageModel>? message = [];
          if (message.isNotEmpty) {
            message.add(MessageModel.fromJson(element.value.data()));
            message[0].docId = element.value.id;
          } else {
            message = [MessageModel.fromJson(element.value.data())];
            message[0].docId = element.value.id;
          }
          DateTimeChip dateTimeChip =
              DateTimeChip(time: getDate(element.value.id), message: message);
          chatCtrl.localMessage.add(dateTimeChip);
        } else {
          int index = chatCtrl.localMessage
              .indexWhere((element) => element.time!.contains("-other"));

          if (!chatCtrl.localMessage[index].message!.contains(messageModel)) {
            chatCtrl.localMessage[index].message!.add(messageModel);
          }
        }
      }
    });

    chatCtrl.update();
  }

  getLocalGroupMessage() {

    final chatCtrl = Get.isRegistered<GroupChatMessageController>()
        ? Get.find<GroupChatMessageController>()
        : Get.put(GroupChatMessageController());
    List<QueryDocumentSnapshot<Object?>> message = chatCtrl.allMessages;
    List reveredList = message.reversed.toList();
    chatCtrl.localMessage = [];

    reveredList.asMap().entries.forEach((element) {
      MessageModel messageModel = MessageModel(
          replyTo: element.value.data()["replyTo"],
          blockBy: element.value.data()["blockBy"],
          blockUserId: element.value.data()["blockUserId"],
          chatId: element.value.data()["chatId"],
          content: element.value.data()["content"],
          docId: element.value.id,
          groupId: element.value.data()["groupId"],
          emoji: element.value.data()["emoji"],
          favouriteId: element.value.data()["favouriteId"],
          isBlock: element.value.data()["isBlock"],
          isBroadcast: element.value.data()["isBroadcast"],
          isFavourite: element.value.data()["isFavourite"],
          isSeen: element.value.data()["isSeen"],
          messageType: element.value.data()["messageType"],
          receiverList: element.value.data()["receiver"],
          senderName: element.value.data()["senderName"],
          sender: element.value.data()["sender"],
          timestamp: element.value.data()["timestamp"],
          replyType: element.value.data()['replyType'],
          replyBy: element.value.data()['replyBy'],
          type: element.value.data()["type"]);
      if (getDate(element.value.id) == "Today") {
        bool isEmpty = chatCtrl.localMessage
            .where((element) => element.time == "Today")
            .isEmpty;
        if (isEmpty) {
          List<MessageModel>? message = [];
          if (message.isNotEmpty) {
            message.add(MessageModel.fromJson(element.value.data()));
            message[0].docId = element.value.id;
          } else {
            message = [MessageModel.fromJson(element.value.data())];
            message[0].docId = element.value.id;
          }
          DateTimeChip dateTimeChip =
              DateTimeChip(time: getDate(element.value.id), message: message);
          chatCtrl.localMessage.add(dateTimeChip);
        } else {
          int index = chatCtrl.localMessage
              .indexWhere((element) => element.time == "Today");

          if (!chatCtrl.localMessage[index].message!.contains(messageModel)) {
            chatCtrl.localMessage[index].message!.add(messageModel);
          }
        }
      }

      if (getDate(element.value.id) == "Yesterday") {
        bool isEmpty = chatCtrl.localMessage
            .where((element) => element.time == "Yesterday")
            .isEmpty;
        if (isEmpty) {
          List<MessageModel>? message = [];
          if (message.isNotEmpty) {
            message.add(MessageModel.fromJson(element.value.data()));
            message[0].docId = element.value.id;
          } else {
            message = [MessageModel.fromJson(element.value.data())];
            message[0].docId = element.value.id;
          }
          DateTimeChip dateTimeChip =
              DateTimeChip(time: getDate(element.value.id), message: message);
          chatCtrl.localMessage.add(dateTimeChip);
        } else {
          int index = chatCtrl.localMessage
              .indexWhere((element) => element.time == "Yesterday");

          if (!chatCtrl.localMessage[index].message!.contains(messageModel)) {
            chatCtrl.localMessage[index].message!.add(messageModel);
          }
        }
      }
      if (getDate(element.value.id).contains("-other")) {
        bool isEmpty = chatCtrl.localMessage
            .where((element) => element.time!.contains("-other"))
            .isEmpty;
        if (isEmpty) {
          List<MessageModel>? message = [];
          if (message.isNotEmpty) {
            message.add(MessageModel.fromJson(element.value.data()));
            message[0].docId = element.value.id;
          } else {
            message = [MessageModel.fromJson(element.value.data())];
            message[0].docId = element.value.id;
          }
          DateTimeChip dateTimeChip =
              DateTimeChip(time: getDate(element.value.id), message: message);
          chatCtrl.localMessage.add(dateTimeChip);
        } else {
          int index = chatCtrl.localMessage
              .indexWhere((element) => element.time!.contains("-other"));

          if (!chatCtrl.localMessage[index].message!.contains(messageModel)) {
            chatCtrl.localMessage[index].message!.add(messageModel);
          }
        }
      }
    });

    chatCtrl.update();
  }

  getLocalBroadcastMessage() {
    final chatCtrl = Get.isRegistered<BroadcastChatController>()
        ? Get.find<BroadcastChatController>()
        : Get.put(BroadcastChatController());
    List<QueryDocumentSnapshot<Object?>> message = chatCtrl.allMessages;
    List reveredList = message.reversed.toList();
    chatCtrl.localMessage = [];

    reveredList.asMap().entries.forEach((element) {
      MessageModel messageModel = MessageModel(
          blockBy: "",
          blockUserId: "",
          broadcastId: element.value.data()["broadcastId"],
          content: element.value.data()["content"],
          docId: element.value.id,
          emoji: element.value.data()["emoji"],
          favouriteId: element.value.data()["favouriteId"],
          isBlock: element.value.data()["isBlock"],
          isBroadcast: element.value.data()["isBroadcast"],
          isFavourite: element.value.data()["isFavourite"],
          isSeen: element.value.data()["isSeen"],
          messageType: element.value.data()["messageType"],
          receiverList: element.value.data()["receiverId"],
          sender: element.value.data()["sender"],
          timestamp: element.value.data()["timestamp"],
          type: element.value.data()["type"]);
      if (getDate(element.value.id) == "Today") {
        bool isEmpty = chatCtrl.localMessage
            .where((element) => element.time == "Today")
            .isEmpty;
        if (isEmpty) {
          List<MessageModel>? message = [];
          if (message.isNotEmpty) {
            message.add(MessageModel.fromJson(element.value.data()));
            message[0].docId = element.value.id;
          } else {
            message = [MessageModel.fromJson(element.value.data())];
            message[0].docId = element.value.id;
          }
          DateTimeChip dateTimeChip =
              DateTimeChip(time: getDate(element.value.id), message: message);
          chatCtrl.localMessage.add(dateTimeChip);
        } else {
          int index = chatCtrl.localMessage
              .indexWhere((element) => element.time == "Today");

          if (!chatCtrl.localMessage[index].message!.contains(messageModel)) {
            chatCtrl.localMessage[index].message!.add(messageModel);
          }
        }
      }

      if (getDate(element.value.id) == "Yesterday") {
        bool isEmpty = chatCtrl.localMessage
            .where((element) => element.time == "Yesterday")
            .isEmpty;
        if (isEmpty) {
          List<MessageModel>? message = [];
          if (message.isNotEmpty) {
            message.add(MessageModel.fromJson(element.value.data()));
            message[0].docId = element.value.id;
          } else {
            message = [MessageModel.fromJson(element.value.data())];
            message[0].docId = element.value.id;
          }
          DateTimeChip dateTimeChip =
              DateTimeChip(time: getDate(element.value.id), message: message);
          chatCtrl.localMessage.add(dateTimeChip);
        } else {
          int index = chatCtrl.localMessage
              .indexWhere((element) => element.time == "Yesterday");

          if (!chatCtrl.localMessage[index].message!.contains(messageModel)) {
            chatCtrl.localMessage[index].message!.add(messageModel);
          }
        }
      }
      if (getDate(element.value.id).contains("-other")) {
        bool isEmpty = chatCtrl.localMessage
            .where((element) => element.time!.contains("-other"))
            .isEmpty;
        if (isEmpty) {
          List<MessageModel>? message = [];
          if (message.isNotEmpty) {
            message.add(MessageModel.fromJson(element.value.data()));
            message[0].docId = element.value.id;
          } else {
            message = [MessageModel.fromJson(element.value.data())];
            message[0].docId = element.value.id;
          }
          DateTimeChip dateTimeChip =
              DateTimeChip(time: getDate(element.value.id), message: message);
          chatCtrl.localMessage.add(dateTimeChip);
        } else {
          int index = chatCtrl.localMessage
              .indexWhere((element) => element.time!.contains("-other"));

          if (!chatCtrl.localMessage[index].message!.contains(messageModel)) {
            chatCtrl.localMessage[index].message!.add(messageModel);
          }
        }
      }
    });

    chatCtrl.update();
  }
}
