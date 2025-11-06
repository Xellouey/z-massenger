import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:async/async.dart';
import 'package:fast_contacts/fast_contacts.dart';

import '../../config.dart';

class UnregisterUser {
  final String phone, name;
  final List<dynamic>? dialCodePhoneList;

  UnregisterUser({
    required this.name,
    required this.phone,
    this.dialCodePhoneList,
  });

  factory UnregisterUser.fromJson(Map<String, dynamic> jsonData) {
    return UnregisterUser(
      phone: jsonData['phone'],
      name: jsonData['name'],
      dialCodePhoneList: jsonData['dialCodePhoneList'],
    );
  }

  static Map<String, dynamic> toMap(UnregisterUser user) => {
    'phone': user.phone,
    'name': user.name,
    'dialCodePhoneList': user.dialCodePhoneList,
  };

  static String encode(List<UnregisterUser> users) => json.encode(
    users
        .map<Map<String, dynamic>>((user) => UnregisterUser.toMap(user))
        .toList(),
  );

  static List<UnregisterUser> decode(String users) =>
      (json.decode(users) as List<dynamic>)
          .map<UnregisterUser>((item) => UnregisterUser.fromJson(item))
          .toList();
}

class RegisterContactDetail {
  final String? phone, dialCode;
  final String? name;
  final String id;
  final String? image;
  final String? statusDesc;

  RegisterContactDetail(
      {this.phone,
        this.name,
        required this.id,
        this.image,
        this.statusDesc,
        this.dialCode});

  factory RegisterContactDetail.fromJson(Map<String, dynamic> jsonData) {
    return RegisterContactDetail(
      id: jsonData['id'],
      name: jsonData['name'],
      phone: jsonData['phone'],
      statusDesc: jsonData['statusDesc'],
      image: jsonData['image'],
    );
  }

  static Map<String, dynamic> toMap(RegisterContactDetail contact) => {
    'id': contact.id,
    'name': contact.name,
    'phone': contact.phone,
    'image': contact.image,
    'statusDesc': contact.statusDesc,
  };

  static String encode(List<RegisterContactDetail> contacts) => json.encode(
    contacts
        .map<Map<String, dynamic>>(
            (contact) => RegisterContactDetail.toMap(contact))
        .toList(),
  );

  static List<RegisterContactDetail> decode(String contacts) =>
      (json.decode(contacts) as List<dynamic>)
          .map<RegisterContactDetail>(
              (item) => RegisterContactDetail.fromJson(item))
          .toList();
}

class ContactProvider extends ChangeNotifier {
  List<Contact> _allContacts = [];
  List<RegisterContactDetail> _registeredContacts = [];
  List<UnregisterUser> _invitedContacts = [];

  List<RegisterContactDetail> searchRegisterContact = [];
  List<UnregisterUser> searchUnRegisterContact = [];

  CollectionReference users = FirebaseFirestore.instance.collection('users');

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<RegisterContactDetail> get registeredContacts => _registeredContacts;

  List<UnregisterUser> get invitedContacts => _invitedContacts;

  List<Contact> get allContacts => _allContacts;

  static Future<bool> checkAndRequestPermission(Permission permission) {
    Completer<bool> completer = Completer<bool>();

    log("COMPLETET");
    permission.request().then((status) {
      if (status != PermissionStatus.granted) {
        permission.request().then((status) {
          bool granted = status == PermissionStatus.granted;

          log("granted :$granted");
          completer.complete(granted);
        });
      } else {
        completer.complete(true);
      }
      log("CONTACT IS FETCH2");
    });
    return completer.future;
  }

  // Fetch contacts from the device for the first time
  Future<void> fetchContacts(phone) async {
    _isLoading = true;
    notifyListeners();
    checkAndRequestPermission(Permission.contacts).then((res) async {
      if (res) {
        appCtrl.storage.write(session.contactPermission, true);
        await FastContacts.getAllContacts().then((contact) {
          _allContacts.clear();
          allContacts.clear();
          for (Contact p in contact.where(
                (element) => element.phones.isNotEmpty,
          )) {
            if (!appCtrl.contactList.contains(p)) {
              appCtrl.contactList.add(p);
            }

            if (!_allContacts.contains(p)) {
              _allContacts.add(p);
            }
          }
        });
        notifyListeners();
        log("_allContacts1 ;${_allContacts.length}");

        await checkContactsInFirebase(phone);
      }
    });
  }

  static List<List<String>> divideIntoChuncks(List<String> array, int size) {
    List<List<String>> chunks = [];
    int i = 0;
    while (i < array.length) {
      int j = i + size;
      chunks.add(array.sublist(i, j > array.length ? array.length : j));
      i = j;
    }
    return chunks;
  }

  static List<List<List<String>>> divideIntoChuncksGroup(
      List<List<String>> array, int size) {
    List<List<List<String>>> chunks = [];
    int i = 0;
    while (i < array.length) {
      int j = i + size;
      chunks.add(array.sublist(i, j > array.length ? array.length : j));
      i = j;
    }
    return chunks;
  }

  Future<List<QueryDocumentSnapshot>?> getUsersUsingChunks(chunks) async {
    QuerySnapshot result = await FirebaseFirestore.instance
        .collection("users")
        .where('dialCodePhoneList', arrayContainsAny: chunks)
        .get();

    if (result.docs.isNotEmpty) {
      return result.docs;
    } else {
      return null;
    }
  }

  // Check contacts in Firebase to see if they are registered or invited
  Future<void> checkContactsInFirebase(phoneNo) async {
    List<String> myArray = _allContacts
        .asMap()
        .entries
        .toList()
        .map((e) => e.value.phones[0].number.replaceAll(" ", "").toString())
        .toList();
    List<List<String>> chunkList = divideIntoChuncks(myArray, 10);
    log("chunkList ;$chunkList");
    List<List<List<String>>> listGroup = divideIntoChuncksGroup(chunkList, 150);

    for (var listGroup in listGroup) {
      var futureGroup = FutureGroup();

      for (var chunk in listGroup) {
        futureGroup.add(getUsersUsingChunks(chunk));
      }
      futureGroup.close();

      var p = await futureGroup.future;
      log(" pp :$p");
      for (var batch in p) {
        if (batch != null) {
          for (QueryDocumentSnapshot<Map<String, dynamic>> registeredUser
          in batch) {
            if (registeredUser.data()["isActive"] == true) {
              List phoneList = registeredUser.data()["dialCodePhoneList"];
              if (!phoneList.contains(phoneNo)) {
                RegisterContactDetail registerContactDetail =
                RegisterContactDetail(
                    phone: registeredUser.data()["phone"],
                    name: registeredUser.data()["name"],
                    image: registeredUser.data()["image"],
                    dialCode: registeredUser.data()["dialCode"] ?? "",
                    statusDesc: registeredUser.data()["statusDesc"],
                    id: registeredUser.data()["id"]);
                if (registeredContacts
                    .where((element) =>
                element.id.toString() == registeredUser.data()["id"])
                    .isEmpty) {
                  log("registeredContacts; ${registeredContacts.length}");
                  registeredContacts.add(registerContactDetail);
                }
              }
              notifyListeners();
            }
          }
        }
      }
    }
    log("registeredContacts :${_invitedContacts.length}");

    for (var c in _allContacts) {
      int index = registeredContacts.indexWhere((element) {
        return element.phone!.contains(c.phones[0].number.replaceAll(" ", ""));
      });
      if (registeredContacts
          .where((element) => element.phone!
          .replaceAll(" ", "")
          .contains(c.phones[0].number.replaceAll(" ", "")))
          .isEmpty) {
        if (_invitedContacts
            .where((element) => element.phone.contains(c.phones[0].number))
            .isEmpty) {
          UnregisterUser unregisterUser =
          UnregisterUser(name: c.displayName, phone: c.phones[0].number);
          if (!_invitedContacts.contains(unregisterUser)) {
            _invitedContacts.add(unregisterUser);
          }
        }
      } else {
        if (_invitedContacts.isNotEmpty) {
          if (index >= 0) {
            _invitedContacts.removeAt(index);
          }
        }
      }

      notifyListeners();
    }
    log("invitedContacts ;${_invitedContacts.length}");

    // Save the results to local storage
    await saveContactsToLocal();
    _isLoading = false;
    notifyListeners();
  }

  static String encode(List<Contact> users) => json.encode(
    users.map<Map<String, dynamic>>((user) => toMap(user)).toList(),
  );

  static Map<String, dynamic> toMap(Contact user) => {
    'id': user.id,
    'phones': user.phones.map((e) => e.toMap()).toList(),
    'emails': user.emails.map((e) => e.toMap()).toList(),
    if (user.structuredName != null)
      'structuredName': user.structuredName!.toMap(),
    if (user.organization != null)
      'organization': user.organization!.toMap(),
  };

  // Save data locally using SharedPreferences
  Future<void> saveContactsToLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    log("_registeredContacts :${_registeredContacts.length}");
    String storageUserString =
    RegisterContactDetail.encode(_registeredContacts);
    String invitedContacts = UnregisterUser.encode(_invitedContacts);
    String allContact = encode(_allContacts);
    log("Hhhh #$storageUserString");
    await prefs.setString('registeredContacts', storageUserString);
    await prefs.setString('invitedContacts', invitedContacts);
    await prefs.setString('allContacts', allContact);
    notifyListeners();
  }

  // Load contacts from local storage
  Future<void> loadContactsFromLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isLoading = true;
    notifyListeners();

    String? registered = prefs.getString('registeredContacts');
    String? invited = prefs.getString('invitedContacts');
    String? allContact = prefs.getString('allContacts');

    if (registered != null && invited != null) {
      _registeredContacts = RegisterContactDetail.decode(registered);
      _invitedContacts = UnregisterUser.decode(invited);
      _allContacts = decode(allContact!);
    }

    _isLoading = false;
    notifyListeners();
  }

  String getInitials(String name) {
    try {
      List<String> names =
      name.trim().replaceAll(RegExp(r'\W'), '').toUpperCase().split(' ');
      names.retainWhere((s) => s.trim().isNotEmpty);
      if (names.length >= 2) {
        return names.elementAt(0)[0] + names.elementAt(1)[0];
      } else if (names.elementAt(0).length >= 2) {
        return names.elementAt(0).substring(0, 2);
      } else {
        return names.elementAt(0)[0];
      }
    } catch (e) {
      return '?';
    }
  }

  Future<bool> checkForLocalSaveOrNot() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? registered = prefs.getString('registeredContacts');
    String? invited = prefs.getString('invitedContacts');

    if (registered != null || invited != null) {
      return true;
    } else {
      return false;
    }
  }

  static List<Contact> decode(String contacts) =>
      (json.decode(contacts) as List<dynamic>)
          .map<Contact>((item) => Contact.fromMap(item))
          .toList();

  searchUser(search) async {

    if (search == "") {
      onBack();
      notifyListeners();
    } else {
      int index = registeredContacts.indexWhere((element) =>
          element.name!.removeAllWhitespace.toLowerCase().contains(search));

      if (index >= 0) {
        if (!searchRegisterContact.contains(registeredContacts[index])) {
          searchRegisterContact.add(registeredContacts[index]);
        }
      }
      int unRegisterIndex = allContacts.indexWhere((element) => element
          .displayName.removeAllWhitespace
          .toLowerCase()
          .contains(search));

      if (unRegisterIndex >= 0) {
        UnregisterUser unregisterUser = UnregisterUser(
            name: allContacts[unRegisterIndex].displayName,
            phone: allContacts[unRegisterIndex].phones[0].number);
        if (!searchUnRegisterContact.contains(unregisterUser)) {
          searchUnRegisterContact.add(unregisterUser);
        }
      }

      notifyListeners();

      /*  registerContactUser
          .asMap()
          .entries
          .forEach((element) {

        if (element.value.name!.toString().removeAllWhitespace.toLowerCase()
            .contains(search)) {
          log("NAME :${element
              .value.name!.toString().removeAllWhitespace.toLowerCase()}");
          log(
              "element.value.name!.toString().removeAllWhitespace.toLowerCase()::${element
                  .value.name!.toString().removeAllWhitespace.toLowerCase()
                  .contains(search)}");
          if (!searchRegisterContactUser.contains(element.value)) {
            searchRegisterContactUser.add(element.value);
          }

          notifyListeners();
        }

        notifyListeners();
      });*/
    }
  }

  onBack() {
    searchRegisterContact = [];
    searchUnRegisterContact = [];
    notifyListeners();
  }
}
