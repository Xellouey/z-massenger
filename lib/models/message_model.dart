class DateTimeChip {
  String? time;
  List<MessageModel>? message;

  DateTimeChip({
    this.time,
    this.message,
  });

  DateTimeChip.fromJson(Map<String, dynamic> json) {
    time = json['time'];
    if (json['message'] != null) {
      message = <MessageModel>[];
      json['message'].forEach((v) {
        message!.add(MessageModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['time'] = time;
    if (message != null) {
      data['message'] = message!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MessageModel {
  String? sender, senderName,replyBy;
  String? receiver;
  String? content;
  String? replyByName;
  String? timestamp, replyTo;
  String? type, groupId, broadcastId;
  String? messageType, chatId, blockBy, blockUserId, emoji, favouriteId, docId,replyType;
  bool? isBlock, isSeen, isBroadcast, isFavourite,isForward;
  List? receiverList, seenMessageList,emojiList;
  String? originalSenderName;

  MessageModel(
      {this.sender,
        this.replyTo,
        this.senderName,
        this.replyBy,
        this.receiverList,
        this.content,
        this.timestamp,
        this.type,
        this. replyByName,
        this.chatId,
        this.messageType,
        this.originalSenderName,
        this.blockBy,
        this.blockUserId,
        this.isBlock = false,
        this.isBroadcast = false,
        this.isForward = false,
        this.isSeen = false,
        this.emoji,
        this.isFavourite = false,
        this.favouriteId,
        this.docId,
        this.groupId,
        this.broadcastId,
        this.replyType,
        this.seenMessageList,
        this.receiver,emojiList});

  MessageModel.fromJson(Map<String, dynamic> json) {
    sender = json["sender"];
    senderName = json['senderName'] ?? '';
    if (!json.containsKey("groupId") && !json.containsKey("broadcastId")) {
      receiver = json['receiver'] ?? '';
    }
    content = json['content'] ?? '';
    timestamp = json['timestamp'];
    docId = json['docId'];
    type = json['type'] ?? '';
    chatId = json['chatId'] ?? '';
    messageType = json['messageType'] ?? "";
    blockBy = json['blockBy'] ?? "";
    replyByName = json['replyByName'] ?? "";

    blockUserId = json['blockUserId'] ?? "";
    if (json.containsKey("originalSenderName")) {
      originalSenderName = json["originalSenderName"] ?? "";
    }
    if (json.containsKey("emoji")) {
      emoji = json['emoji'] ?? "";
    }
    if (json.containsKey("replyTo")) {
      replyTo = json['replyTo'] ?? '';
    } if (json.containsKey("replyType")) {
      replyType = json['replyType'] ?? '';
    } if (json.containsKey("replyBy")) {
      replyBy = json['replyBy'] ?? '';
    }

    if (json.containsKey("favouriteId")) {
      favouriteId = json['favouriteId'] ?? "";
    }
    if (json.containsKey("isBlock")) {
      isBlock = json['isBlock'] ?? "";
    } else {
      isBlock = false;
    }
    isBroadcast = json['isBroadcast'] ?? false;
    isForward = json['isForward'] ?? false;
    isSeen = json['isSeen'] ?? false;
    if (json.containsKey("isFavourite")) {
      isFavourite = json['isFavourite'] ?? false;
    }
    if (json.containsKey("groupId") || json.containsKey("broadcastId")) {
      if (json.containsKey("receiver")) {
        receiverList = json['receiver'] ?? [];
      }
    }
    if (json.containsKey("groupId") || json.containsKey("broadcastId")) {
      groupId = json['groupId'] ?? "";
    }
    if (json.containsKey("seenMessageList")) {
      seenMessageList = json['seenMessageList'] ?? "";
    }
    if (json.containsKey("emojiList")) {
      emojiList = json['emojiList'] ?? [];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sender'] = sender;
    data['senderName'] = senderName;
    data['receiver'] = receiver;
    data['replyBy'] = replyBy;
    data['content'] = content;
    data['timestamp'] = timestamp;
    data['originalSenderName'] = originalSenderName;
    data['docId'] = docId;
    data['type'] = type;
    data['chatId'] = chatId;
    data['replyTo'] = replyTo;
    data['replyType'] = replyType;
    data['messageType'] = messageType;
    data['blockBy'] = blockBy;
    data['isForward'] = isForward;
    data['blockUserId'] = blockUserId;
    data['emoji'] = emoji;
    data['favouriteId'] = favouriteId;
    data['isBlock'] = isBlock;
    data['isBroadcast'] = isBroadcast;
    data['isSeen'] = isSeen;
    data['replyByName'] = replyByName;
    data['isFavourite'] = isFavourite;
    data['receiverList'] = receiverList;
    data['groupId'] = groupId;
    data['seenMessageList'] = seenMessageList;
    data['broadcastId'] = broadcastId;
    data['emojiList'] = emojiList;

    return data;
  }
}
