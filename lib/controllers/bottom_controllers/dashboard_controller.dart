import 'dart:async';
import 'dart:developer';
import 'package:chatzy/config.dart';
import 'package:chatzy/controllers/bottom_controllers/call_list_controller.dart';
import 'package:chatzy/controllers/recent_chat_controller.dart';
import 'package:chatzy/screens/app_screens/select_contact_screen/fetch_contacts.dart';
import 'package:chatzy/screens/bottom_screens/call_screen/call_screen.dart';
import 'package:chatzy/screens/bottom_screens/call_screen/layouts/contact_call.dart';
import 'package:chatzy/screens/bottom_screens/chat_screen/chat_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:country_codes/country_codes.dart';
import 'package:flutter/services.dart';
import '../../screens/bottom_screens/setting_screen/setting_screen.dart';
import '../app_pages_controllers/language_controller.dart';
import '../common_controllers/all_permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;

class DashboardController extends GetxController
    with GetSingleTickerProviderStateMixin {
  List bottomNavLists = [];
  int selectIndex = 0;
  TabController? tabController;
  String? data;


  int selectedIndex = 0;
  int selectedPopTap = 0;
  late int iconCount = 0;
  Timer? timer;
  List bottomList = [];
  bool isLoading = true, isLongPress = false;
  bool isSearch = false;
  int counter = 0;
  List<Map<String, dynamic>> contactsData = [];
  List<Map<String, dynamic>> unRegisterContactData = [];
  TextEditingController searchText = TextEditingController();
  TextEditingController userText = TextEditingController();
  List selectedChat = [];
  List<ConnectivityResult> connectionStatus = [];  final Connectivity connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> connectivitySubscription;
  SharedPreferences? prefs;

  final messageCtrl = Get.isRegistered<ChatDashController>()
      ? Get.find<ChatDashController>()
      : Get.put(ChatDashController());

  final permissionHandelCtrl = Get.isRegistered<PermissionHandlerController>()
      ? Get.find<PermissionHandlerController>()
      : Get.put(PermissionHandlerController());

  final statusCtrl = Get.isRegistered<StatusController>()
      ? Get.find<StatusController>()
      : Get.put(StatusController());
  final callCtrl = Get.isRegistered<CallListController>()
      ? Get.find<CallListController>()
      : Get.put(CallListController());

  onChange(val) async {
    selectedIndex = val;
    if (val == 1) {}
  }

  int backCounter=0;

  onWillPop() {
    if (backCounter == 0) {
      Fluttertoast.showToast(msg: "Back Press Again");
      backCounter++;
      update();
    } else {
      backCounter =0;
      update();
      SystemNavigator.pop();
    }

  }

  addDataInList() async {
    appCtrl.registerContact = [];
    appCtrl.update();
    contactsData.asMap().entries.forEach((element) {
      if (element.value["phone"] != appCtrl.user["phone"]) {
        if (!appCtrl.registerContact
            .contains(FirebaseContactModel.fromJson(element.value))) {
          appCtrl.registerContact
              .add(FirebaseContactModel.fromJson(element.value));
        }
        update();
      }
    });

    appCtrl.storage.write(session.registerUser, appCtrl.registerContact);

    unRegisterContactData.asMap().entries.forEach((element) {
      if (element.value["phone"] != appCtrl.user["phone"]) {
        if (!appCtrl.unRegisterContact
            .contains(FirebaseContactModel.fromJson(element.value))) {
          appCtrl.unRegisterContact
              .add(FirebaseContactModel.fromJson(element.value));
        }
        update();
      }
    });

    appCtrl.storage.write(session.unRegisterUser, appCtrl.unRegisterContact);

    appCtrl.update();
    log("AFTER LOGIN :: ${appCtrl.registerContact.length}");
    log("AFTER LOGIN :: ${appCtrl.unRegisterContact.length}");
    Get.forceAppUpdate();
  }


  getFirebaseContact() async {
    debugPrint(
        "appCtrl.unRegisterContact : ${appCtrl.unRegisterContact.length}");
    await Future.delayed(DurationsClass.s3);

    await addDataInList();
    await Future.delayed(DurationsClass.s3);
    log("DOOOOOO");
  }

  Stream onSearch(val) {
    if (selectedIndex == 0) {
      return FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(messageCtrl.currentUserId)
          .collection(collectionName.chats)
          .where("name", isEqualTo: val)
          .orderBy("updateStamp", descending: true)
          .limit(15)
          .snapshots();
    } else if (selectedIndex == 1) {
      return FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(messageCtrl.currentUserId)
          .collection(collectionName.chats)
          .where("name", isEqualTo: val)
          .orderBy("updateStamp", descending: true)
          .limit(15)
          .snapshots();
    } else {
      Stream<QuerySnapshot<Map<String, dynamic>>>? snapshots = FirebaseFirestore
          .instance
          .collection(collectionName.calls)
          .doc(appCtrl.user["id"])
          .collection(collectionName.collectionCallHistory)
          .where("callerName", isEqualTo: val)
          .orderBy("timestamp", descending: true)
          .snapshots();
      return snapshots;
    }
  }

  Stream callData(val) {
    Stream<QuerySnapshot<Map<String, dynamic>>>? snapshots = FirebaseFirestore
        .instance
        .collection(collectionName.calls)
        .doc(appCtrl.user["id"])
        .collection(collectionName.collectionCallHistory)
        .where("callerName", isEqualTo: val)
        .orderBy("timestamp", descending: true)
        .snapshots();
    return snapshots;
  }

  onTapActionButton() {
    if (tabController?.index == 0) {
      Get.to(() => FetchContact(prefs: prefs));
    } else if (tabController?.index == 1) {
      Get.to(() => ContactCall());
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await connectivity.checkConnectivity();
    } on PlatformException {
      debugPrint('Couldn\'t check connectivity status');
      return;
    }

    return updateConnectionStatus(result);
  }

  Future<void> updateConnectionStatus(List<ConnectivityResult> result) async {
    connectionStatus = result;
    update();
  }

  // All BottomNavigation Pages
  final List<Widget> pages = [
    ChatScreen(),
    CallScreen(),
    SettingScreen(),
    ProfileScreen(),
  ];

  fetch() async {
    final Locale systemLocales =
        WidgetsBinding.instance.platformDispatcher.locale;
    log("LOCAKE : $systemLocales");
    final CountryDetails deviceLocale = CountryCodes.detailsForLocale();
    log("LOCAKE : ${deviceLocale.localizedName}");
    tz.initializeTimeZones();

    /*var detroit = tz.getLocation(deviceLocale.localizedName!);
    var now = tz.TZDateTime.now(detroit);
    var timeZone = detroit.timeZone(now.millisecondsSinceEpoch);
    log("timeZone : $timeZone");
    log("timeZone : $now");*/
  }

  fetchLan() async {
    final lan = Get.isRegistered<LanguageController>()
        ? Get.find<LanguageController>()
        : Get.put(LanguageController());
    lan.getLanguageList();
    await CountryCodes.init();
    fetch();
  }

  @override
  void onReady() async {
    log("-=-=-=-=-=-=-=-=-=${appCtrl.storage.read(session.locale)}', '${appCtrl.storage.read(session.countryCode)}");
    var dataFetch = appCtrl.storage.read(session.user);
    statusCtrl.getCurrentStatus();
    data = dataFetch["image"];
    
    // Update FCM token on Dashboard launch (app resume scenario)
    try {
      final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
      String? token = await firebaseMessaging.getToken();
      
      if (token != null && appCtrl.user["id"] != null) {
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(appCtrl.user["id"])
            .update({
          'pushToken': token,
          'lastTokenUpdate': DateTime.now().millisecondsSinceEpoch.toString()
        });
        
        debugPrint('FCM Token updated on Dashboard launch: $token');
      }
    } catch (e) {
      debugPrint('Failed to update FCM token on Dashboard launch: $e');
    }
    
    firebaseCtrl.setIsActive();

    // Clean up old/stale calls from Firestore
    await _cleanupOldCalls();

    // CLEANUP DUPLICATE CHATS - Run this ONCE after update, then comment out
    // Uncomment the line below to clean up existing duplicate chats:
    // await cleanupDuplicateChats();

    update();
    bottomNavLists = appArray.bottomNavyList;
    await Future.delayed(DurationsClass.s2);
    statusCtrl.getAllStatus();
    callCtrl.getAllCallList();

    tabController =
        TabController(length: appArray.bottomNavyList.length, vsync: this);
    update();
    tabController!.addListener(() {
      update();
      log("SELCTED: %${tabController!.index}");
      callCtrl.isSearch = false;
      callCtrl.update();
      isSearch = false;
      update();
    });
    update();
    Get.forceAppUpdate();
    fetchLan();

    // TODO: implement onReady
    super.onReady();
  }


  //pin all chat
  pinAllChat() async {
    selectedChat.asMap().entries.forEach(
          (element) async {
        log("EEEEE :${element.value}");
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(appCtrl.user["id"])
            .collection(collectionName.chats)
            .doc(element.value)
            .update({"isPin": true}).then((value) {

        },).catchError((e){
          log("EE :$e");
        });
      },
    );
    await Future.delayed(DurationsClass.s1);
    isLongPress= false;
    selectedChat = [];
    update();
  }

  //delete all selected chats
  deleteAllChats() async {
    // Show confirmation dialog
    bool? confirm = await Get.dialog(
      AlertDialog(
        backgroundColor: appCtrl.appTheme.white,
        title: Text(
          appFonts.deleteChatId.tr,
          style: AppCss.manropeblack16.textColor(appCtrl.appTheme.darkText),
        ),
        content: Text(
          "Are you sure you want to delete ${selectedChat.length} chat(s)?",
          style: AppCss.manropeMedium14.textColor(appCtrl.appTheme.darkText),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(appFonts.cancel.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(appFonts.deleteChat.tr),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Delete each selected chat
      for (var element in selectedChat) {
        log("Deleting chat: $element");

        // Get the chat document to find chatId or groupId
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(appCtrl.user["id"])
            .collection(collectionName.chats)
            .doc(element)
            .get()
            .then((chatDoc) async {
          if (chatDoc.exists) {
            var chatData = chatDoc.data();

            // Delete messages
            if (chatData?["chatId"] != null) {
              // Single chat - delete messages
              await FirebaseFirestore.instance
                  .collection(collectionName.users)
                  .doc(appCtrl.user["id"])
                  .collection(collectionName.messages)
                  .doc(chatData!["chatId"])
                  .collection(collectionName.chat)
                  .get()
                  .then((messages) {
                if (messages.docs.isNotEmpty) {
                  for (var msg in messages.docs) {
                    msg.reference.delete();
                  }
                }
              });
            } else if (chatData?["groupId"] != null) {
              // Group chat - delete messages
              await FirebaseFirestore.instance
                  .collection(collectionName.users)
                  .doc(appCtrl.user["id"])
                  .collection(collectionName.groupMessage)
                  .doc(chatData!["groupId"])
                  .collection(collectionName.chat)
                  .get()
                  .then((messages) {
                if (messages.docs.isNotEmpty) {
                  for (var msg in messages.docs) {
                    msg.reference.delete();
                  }
                }
              });
            }

            // Delete the chat document
            await chatDoc.reference.delete();
          }
        }).catchError((e) {
          log("Error deleting chat: $e");
        });
      }

      await Future.delayed(DurationsClass.s1);
      isLongPress = false;
      selectedChat = [];
      update();
    }
  }

  // Clean up old/stale calls from Firestore
  // This prevents old call notifications from appearing on app launch
  Future<void> _cleanupOldCalls() async {
    try {
      if (appCtrl.user == null || appCtrl.user["id"] == null) {
        log("⚠️ Cannot cleanup calls: user not logged in");
        return;
      }

      final userId = appCtrl.user["id"];
      log("🧹 Cleaning up old calls for user: $userId");

      // Get all active calls from 'calling' collection
      final callingSnapshot = await FirebaseFirestore.instance
          .collection(collectionName.calls)
          .doc(userId)
          .collection(collectionName.calling)
          .get();

      if (callingSnapshot.docs.isEmpty) {
        log("✅ No old calls to cleanup");
        return;
      }

      log("Found ${callingSnapshot.docs.length} old call(s) to cleanup");

      // Delete all old calls in a batch
      final batch = FirebaseFirestore.instance.batch();
      int deletedCount = 0;

      for (var doc in callingSnapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'];
        final now = DateTime.now().millisecondsSinceEpoch;

        // Delete calls older than 1 minute (60000 ms)
        // This ensures we don't delete actual incoming calls
        if (timestamp != null && (now - timestamp) > 60000) {
          log("Deleting old call from ${data['callerName']} (timestamp: $timestamp)");
          batch.delete(doc.reference);
          deletedCount++;
        } else {
          log("⚠️ Keeping recent call from ${data['callerName']} (timestamp: $timestamp)");
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
        log("✅ Successfully deleted $deletedCount old call(s)");
      } else {
        log("ℹ️ No old calls found to delete (all calls are recent)");
      }

    } catch (e, stackTrace) {
      log("❌ Error cleaning up old calls: $e");
      log("Stack trace: $stackTrace");
    }
  }

  // Clean up duplicate chats (run once after fixing the duplicate chat bug)
  Future<void> cleanupDuplicateChats() async {
    try {
      if (appCtrl.user == null || appCtrl.user["id"] == null) {
        log("⚠️ Cannot cleanup chats: user not logged in");
        return;
      }

      var userId = appCtrl.user["id"];
      log("🧹 Starting duplicate chat cleanup for user: $userId");

      var chatsSnapshot = await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(userId)
          .collection(collectionName.chats)
          .where("isOneToOne", isEqualTo: true)
          .get();

      if (chatsSnapshot.docs.isEmpty) {
        log("ℹ️ No chats found to check");
        return;
      }

      Map<String, List<DocumentSnapshot>> chatsByUser = {};

      // Group chats by other participant
      for (var doc in chatsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Determine the other participant in the chat
        String? otherUserId;
        if (data["senderId"] == userId) {
          otherUserId = data["receiverId"];
        } else if (data["receiverId"] == userId) {
          otherUserId = data["senderId"];
        }

        if (otherUserId == null || otherUserId.isEmpty) {
          log("⚠️ Skipping chat with invalid participant data: ${doc.id}");
          continue;
        }

        if (!chatsByUser.containsKey(otherUserId)) {
          chatsByUser[otherUserId] = [];
        }
        chatsByUser[otherUserId]!.add(doc);
      }

      // Delete duplicates, keeping the most recent one
      int deletedCount = 0;
      for (var entry in chatsByUser.entries) {
        if (entry.value.length > 1) {
          log("Found ${entry.value.length} duplicate chats for user: ${entry.key}");

          // Sort by updateStamp (most recent first)
          entry.value.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            int stampA = int.tryParse(dataA["updateStamp"] ?? "0") ?? 0;
            int stampB = int.tryParse(dataB["updateStamp"] ?? "0") ?? 0;
            return stampB.compareTo(stampA); // Descending order
          });

          // Delete all except the first one (most recent)
          for (int i = 1; i < entry.value.length; i++) {
            await entry.value[i].reference.delete();
            deletedCount++;
            log("Deleted duplicate chat: ${entry.value[i].id}");
          }
        }
      }

      log("✅ Cleanup complete: deleted $deletedCount duplicate chat(s)");

      if (deletedCount > 0) {
        Fluttertoast.showToast(
          msg: "Удалено дубликатов чатов: $deletedCount",
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e, stackTrace) {
      log("❌ Error cleaning up duplicate chats: $e");
      log("Stack trace: $stackTrace");
    }
  }

  @override
  void onClose() {
    // Cancel subscriptions to prevent memory leaks
    connectivitySubscription.cancel();
    log("DashboardController: Subscriptions cancelled");
    super.onClose();
  }
}
