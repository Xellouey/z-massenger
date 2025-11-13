import 'dart:developer';

import '../../config.dart';
import '../../models/call_model.dart';
import '../common_controllers/contact_controller.dart';

class CallListController extends GetxController {
  List settingList = [];
  dynamic user;
  bool isSearch = false;
  bool isContactSearch = false;
  TextEditingController searchText = TextEditingController();
  TextEditingController searchContactText = TextEditingController();
  bool bannerAdIsLoaded = false;
  List<RegisterContactDetail> searchList = [];
  DateTime now = DateTime.now();
  Stream? stream;
  List<DocumentSnapshot> results = [];
  int selectedIndex = -1; // -1 means no item is selected

  List selectedIndices = []; // List of selected indices
  List selectedMissIndices = []; // List of selected indices

  List<QueryDocumentSnapshot<Object?>> inComing = [];
  List<QueryDocumentSnapshot<Object?>> callingList = [];

/*  List<QueryDocumentSnapshot<Object?>> results = [];

  void onSearch(String query) {

    results = inComing
        .where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data["name"]?.toString().toLowerCase() ?? "";
      return name.contains(query.toLowerCase());
    })
        .toList();
    log("results::: ${results}");
    update();
  }*/

  // Function to toggle selection for multiple items
  void toggleSelection(index) {
    if (selectedIndices.isEmpty) {
      // Start fresh if the list is empty
      selectedIndices.clear();
    }

    if (selectedIndices.contains(index)) {
      log("ffdhfgmessage${selectedIndices.contains(index)}");
      selectedIndices.remove(index);
      log("ffdhfgmessage${selectedIndices.remove(index)}");
      // Deselect if already selected
    } else {
      selectedIndices.add(index); // Select if not selected
    }
    update(); // Update UI
  } // Function to toggle selection for multiple items

  void toggleMissCallSelection(index) {
    if (selectedMissIndices.isEmpty) {
      // Start fresh if the list is empty
      selectedMissIndices.clear();
    }

    if (selectedMissIndices.contains(index)) {
      log("ffdhfgmessage${selectedMissIndices.contains(index)}");
      selectedMissIndices.remove(index);
      log("ffdhfgmessage${selectedMissIndices.remove(index)}");
      // Deselect if already selected
    } else {
      selectedMissIndices.add(index); // Select if not selected
    }
    update(); // Update UI
  }

  bool isSelected(index) {
    log("ftfgth::: $index");
    log("selectedIndices.contains(index):::${selectedIndices.contains(index)}");
    return selectedIndices.contains(index); // Check if the item is selected
  }

  // To check if the selection is active or not
  bool isSelectionActive() {
    return selectedIndices.isNotEmpty; // If there are any selected items
  }

  // Function to clear all selections
  void clearSelection() {
    selectedIndices.clear(); // Clear all selections
    update();
  } // To check if the selection is active or not

  bool isMissCallSelected(index) {
    log("ftfgth::: $index");
    log("selectedIndices.contains(index):::${selectedIndices.contains(index)}");
    return selectedMissIndices.contains(index); // Check if the item is selected
  }

  bool isMissCallSelectionActive() {
    return selectedMissIndices.isNotEmpty; // If there are any selected items
  }

  // Function to clear all selections
  void clearMissCallSelection() {
    selectedMissIndices.clear(); // Clear all selections
    update();
  }

  @override
  void onReady() {
    // TODO: implement onReady
    stream = FirebaseFirestore.instance
        .collection(collectionName.calls)
        .doc(appCtrl.user["id"])
        .collection(collectionName.collectionCallHistory)
        .orderBy("timestamp", descending: true)
        .snapshots();

    super.onReady();
  }

  buildPopupDialog() async {
    await showDialog(
      context: Get.context!,
      builder: (_) => GetBuilder<CallListController>(builder: (callListCtrl) {
        return AlertDialog(
          backgroundColor: appCtrl.appTheme.screenBG,
          title: Text(appFonts.alert.tr),
          content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Are you sure you want to delete the selected call(s)?")
              ]),
          actions: <Widget>[
            TextButton(onPressed: () => Get.back(), child: const Text('Close')),
            TextButton(
              onPressed: () async {
                Get.back();
                if (selectedIndices != []) {
                  // Fetch the user's call history
                  for (var d in selectedIndices) {
                    await FirebaseFirestore.instance
                        .collection(collectionName.calls)
                        .doc(appCtrl.user["id"])
                        .collection(collectionName.collectionCallHistory)
                        .doc(d)
                        .delete();
                  }
                  log("fdsfddsfdfsdfdfsfdsfds:::${selectedIndices}");
                }
                if (selectedMissIndices != []) {
                  for (var data in selectedMissIndices) {
                    await FirebaseFirestore.instance
                        .collection(collectionName.calls)
                        .doc(appCtrl.user["id"])
                        .collection(collectionName.collectionCallHistory)
                        .doc(data)
                        .delete();
                  }
                  log("fhuaifgdysfg:::${selectedMissIndices}");
                }

                // Clear selection after deletion
                clearSelection();
                clearMissCallSelection();
                update();
                Get.back();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      }),
    );
  }

  callList() async {
    int count = 0;
    FirebaseFirestore.instance
        .collection(collectionName.users)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        value.docs.asMap().entries.forEach((e) {
          FirebaseFirestore.instance
              .collection(collectionName.calls)
              .doc(e.value.id)
              .collection(collectionName.collectionCallHistory)
              .get()
              .then((value) {
            count = count + value.docs.length;
            update();
          });
        });
      }
    });
  }

  onSearch(val) async {
    QuerySnapshot<Map<String, dynamic>> query1 = await FirebaseFirestore
        .instance
        .collection(collectionName.calls)
        .doc(appCtrl.user["id"])
        .collection(collectionName.collectionCallHistory)
        .where("callerName",
        isGreaterThanOrEqualTo: val.toString().toLowerCase())
        .get();
    log("query1 :% ${query1.docs.length}");
    QuerySnapshot<Map<String, dynamic>> query2 = await FirebaseFirestore
        .instance
        .collection(collectionName.calls)
        .doc(appCtrl.user["id"])
        .collection(collectionName.collectionCallHistory)
        .where("receiverName",
        isGreaterThanOrEqualTo: val.toString().toLowerCase())
        .get();

    QuerySnapshot<Map<String, dynamic>> query3 = await FirebaseFirestore
        .instance
        .collection(collectionName.calls)
        .doc(appCtrl.user["id"])
        .collection(collectionName.collectionCallHistory)
        .where("callerName",
        isGreaterThanOrEqualTo: val.toString().capitalizeFirst)
        .get();
    QuerySnapshot<Map<String, dynamic>> query4 = await FirebaseFirestore
        .instance
        .collection(collectionName.calls)
        .doc(appCtrl.user["id"])
        .collection(collectionName.collectionCallHistory)
        .where("receiverName",
        isGreaterThanOrEqualTo: val.toString().capitalizeFirst)
        .get();

    results = query1.docs + query2.docs + query3.docs + query4.docs;
    update();
    return results;
  }

  onContactSearch(val) {
    // log("valval : ${val != ""}");
    if (val != "") {
      final ContactProvider availableContacts =
      Provider.of<ContactProvider>(Get.context!, listen: false);
      availableContacts.registeredContacts.asMap().entries.forEach((element) {
        if (element.value.name!
            .replaceAll(" ", "")
            .toLowerCase()
            .contains(val.toString().toLowerCase())) {
          if (searchList.isEmpty) {
            searchList = [element.value];
          } else {
            log("ELEMENT11 ${searchList.contains(element.value)}");

            if (!searchList.contains(element.value)) {
              searchList.add(element.value);
              update();
            }
          }
          update();
          Get.forceAppUpdate();
        }
      });
    } else {
      log("fjxghcdfkjhg");
      searchList = [];
      update();
    }
    log("isDATSF $searchList");
  }

  //audio and video call tap
  audioVideoCallTap(isVideoCall, pData) async {
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(pData["id"] == appCtrl.user["id"]
        ? pData["receiverId"]
        : pData["id"])
        .get()
        .then((value) {
      if (value.exists) {
        pData["receiverName"] = value.data()!["name"];
        pData["receiverName"] = value.data()!["name"];
        pData["receiverToken"] = value.data()!["pushToken"];
      }
      update();
    });

    await audioAndVideoCallApi(toData: pData, isVideoCall: isVideoCall);
  }

  callFromList(isVideoCall, pData) async {
    await audioAndVideoCallApi(toData: pData, isVideoCall: isVideoCall);
  }

  audioAndVideoCallApi({toData, isVideoCall}) async {
    try {
      var userData = appCtrl.storage.read(session.user);

      // Проверка: нельзя звонить самому себе
      if (userData["id"] == toData["id"]) {
        log("ERROR: Cannot call yourself!");
        Fluttertoast.showToast(msg: "You cannot call yourself");
        return;
      }

      int timestamp = DateTime.now().millisecondsSinceEpoch;

      Map<String, dynamic>? response =
      await firebaseCtrl.getAgoraTokenAndChannelName();

      log("FUNCTION ; $response");
      if (response != null) {
        String channelId = response["channelName"];
        String token = response["agoraToken"];
        Call call = Call(
            timestamp: timestamp,
            callerId: userData["id"],
            callerName: userData["name"],
            callerPic: userData["image"],
            receiverId: toData["id"],
            receiverName: toData["name"],
            receiverPic: toData["image"],
            callerToken: userData["pushToken"],
            receiverToken: toData["pushToken"],
            channelId: channelId,
            isVideoCall: isVideoCall,
            agoraToken: token,
            receiver: []);

        await FirebaseFirestore.instance
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
          "receiverToken": toData["pushToken"],
          "hasDialled": true,
          "channelId": channelId,
          "isVideoCall": isVideoCall,
          "agoraToken": token,
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
            "receiverId": toData["id"],
            "receiverName": toData["name"],
            "receiverPic": toData["image"],
            "callerToken": userData["pushToken"],
            "receiverToken": toData["pushToken"],
            "hasDialled": false,
            "channelId": channelId,
            "isVideoCall": isVideoCall,
            "agoraToken": token,
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
      } else {
        Fluttertoast.showToast(msg: "Не удалось позвонить");
      }
    } on FirebaseException catch (e) {
      // Caught an exception from Firebase.
      log("Failed with error '${e.code}': ${e.message}");
    }
  }

  getAllCallList() async {
    await FirebaseFirestore.instance
        .collection(collectionName.calls)
        .doc(appCtrl.user["id"])
        .collection(collectionName.collectionCallHistory)
        .orderBy("timestamp", descending: true)
        .get()
        .then((value) {
      inComing = value.docs
          .where((element) =>
      element.data()['type'] == "missedCall" ||
          element.data()['started'] == null ||
          element.data()['status'] == "rejected")
          .toList();

      update();
    });

    await FirebaseFirestore.instance
        .collection(collectionName.calls)
        .doc(appCtrl.user["id"])
        .collection(collectionName.collectionCallHistory)
        .orderBy("timestamp", descending: true)
        .get()
        .then((value) {
      callingList = value.docs
          .where((element) =>
      element.data()['type'] != "missedCall" ||
          element.data()['started'] != null ||
          element.data()['status'] == "pickedUp")
          .toList();
      update();
    });
  }
/*  getAllCallList()async{
    await FirebaseFirestore.instance
        .collection(collectionName.calls)
        .doc(appCtrl.user["id"])
        .collection(collectionName.collectionCallHistory)
        .orderBy("timestamp", descending: true).get().then((value){
      inComing = value.docs.where((element) => element.data()['type'] =="missedCall" || element.data()['started'] == null || element.data()['status'] == "rejected").toList();

      update();
    });

    await FirebaseFirestore.instance
        .collection(collectionName.calls)
        .doc(appCtrl.user["id"])
        .collection(collectionName.collectionCallHistory)
        .orderBy("timestamp", descending: true).get().then((value){
      callingList = value.docs.where((element) => element.data()['type'] !="missedCall" ||element.data()['started'] != null || element.data()['status'] == "pickedUp" ).toList();
      update();
    });
  }*/
}
