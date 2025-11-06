import 'dart:convert';
import 'dart:developer';
import '../config.dart';

class RecentChatController with ChangeNotifier {
  List<QueryDocumentSnapshot<Map<String, dynamic>>> userData = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> messageList = [],
      searchList = [];
  List<Widget> messageWidgetList = [];


  notify() {
    notifyListeners();
  }

  checkChatList(SharedPreferences pref) {
    appCtrl.storage.remove(session.chatList);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appCtrl.update();
    });
    String? registered = pref.getString(session.chatList);
    log("messageList:$registered");
    if(registered != null) {
      List jsonData = jsonDecode(registered);
      log("messageList:$registered");
      // Cast the dynamic list to List<Map<String, dynamic>>
      messageList = jsonData
          .map((item) {
        log("ITEM :$item");
        return item as QueryDocumentSnapshot<Map<String, dynamic>>;
      })
          .toList();
      notifyListeners();

    }else{  log("ITEM :${pref.getString(session.chatList)}");}
    getMessageList();
  }

  onSearch(text) {
    searchList = messageList;
    if (text != null) {
      messageList = messageList
          .where(
            (element) => element.data()['name'].contains(text),
      )
          .toList();
    } else {
      messageList = searchList;
    }
    notifyListeners();
  }
  void getMessageList() {
    FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(appCtrl.user["id"])
        .collection(collectionName.chats)
        .orderBy("updateStamp", descending: true)
        .snapshots()
        .listen((chatsWith) {
      List<QueryDocumentSnapshot<Map<String, dynamic>>> pinList = [];
      List<QueryDocumentSnapshot<Map<String, dynamic>>> unPinList = [];

      for (var c in chatsWith.docs) {
        if (c.data()['isPin'] == true) {
          pinList.add(c);
        } else {
          unPinList.add(c);
        }
      }

      messageList = [...pinList, ...unPinList];

      // Save to local
      List<Map<String, dynamic>> docsAsMaps = messageList.map((doc) {
        return {
          "id": doc.id,
          "data": doc.data(),
        };
      }).toList();

      appCtrl.storage.write(session.chatList, jsonEncode(docsAsMaps));

      notifyListeners(); // 🔥 This triggers UI rebuild instantly
    });
  }

  // getMessageList() async {
  //   SharedPreferences pref = await SharedPreferences.getInstance();
  //   List<QueryDocumentSnapshot<Map<String, dynamic>>> pinList = [];
  //
  //   List<QueryDocumentSnapshot<Map<String, dynamic>>> unPinList = [];
  //
  //   FirebaseFirestore.instance
  //       .collection(collectionName.users)
  //       .doc(appCtrl.user["id"])
  //       .collection(collectionName.chats)
  //       .orderBy("updateStamp", descending: true)
  //       .snapshots()
  //       .listen((chatsWith) {
  //
  //     if (chatsWith.docs.isNotEmpty) {
  //
  //       for (var c in chatsWith.docs) {
  //         log("_chatsWithexists : ${chatsWith.docs.first.data()}////$c");
  //         if ((c.data()).containsKey('isPin') && c.data()['isPin'] == true) {
  //           if (pinList.where((element) => element.id == c.id).isEmpty) {
  //             pinList.add(c);
  //           }
  //           notifyListeners();
  //         }
  //         if (!(c.data()).containsKey('isPin') || ((c.data()).containsKey('isPin') &&
  //             c.data()['isPin'] == false)) {
  //           if (unPinList.where((element) => element.id == c.id).isEmpty) {
  //             unPinList.add(c);
  //           }
  //           notifyListeners();
  //         }
  //       }
  //
  //       notifyListeners();
  //     }
  //     print("pinList :${pinList.length}");
  //   });
  //
  //
  //   await Future.delayed(DurationsClass.s1);
  //   messageList = pinList + unPinList;
  //   notifyListeners();
  //   print('messageList 1:$messageList');
  //   String jsonString = encodeDocuments(messageList);
  //   appCtrl.storage.write(session.chatList, jsonEncode(jsonString));
  //   appCtrl.update();
  //   /*List<QueryDocumentSnapshot<Map<String, dynamic>>> documentsData = messageList.map((doc) {
  //     return doc;  // Extract only the Map<String, dynamic> from each document
  //   }).toList();
  //   // Encode the list into a JSON string
  //   String jsonString = jsonEncode(documentsData);
  //   print("sfd L${messageList.length}");
  //   await pref.setString(session.chatList, jsonString);*/
  //   notifyListeners();
  //
  // }

  String encodeDocuments(List<QueryDocumentSnapshot<Map<String, dynamic>>> documents) {
    List<Map<String, dynamic>> documentDataList = documents.map((doc) {
      return {
        'id': doc.id,          // Add the document ID
        'data': doc.data(),    // Add the document data (Map<String, dynamic>)
        'metadata': {          // Optionally add metadata (can be expanded if needed)
          'hasPendingWrites': doc.metadata.hasPendingWrites,
          'isFromCache': doc.metadata.isFromCache,
        }
      };
    }).toList();

    // Encode the list of maps into a JSON string
    String jsonString = jsonEncode(documentDataList);

    return jsonString;  // Return the JSON string
  }
}
