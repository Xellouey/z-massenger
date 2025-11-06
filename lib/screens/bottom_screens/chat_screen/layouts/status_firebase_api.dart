import 'dart:developer';

import 'package:fast_contacts/fast_contacts.dart';

import '../../../../config.dart';
import '../../../../models/status_model.dart';

class StatusFirebaseApi {
  //add status


  addStatus(imageUrl, statusType, {statusText, statusBgColor}) async {
    log("=== addStatus called ===");
    var user = appCtrl.storage.read(session.user);
    log("Publishing status for user: ${user['id']} (${user['name']})");
    log("Status type: $statusType");
    List<PhotoUrl> statusImageUrls = [];
    int minHrs = appCtrl.usageControlsVal!.statusDeleteTime!.contains(" hrs")
        ? int.parse(
        appCtrl.usageControlsVal!.statusDeleteTime!.split(" hrs")[0])
        : int.parse(
        appCtrl.usageControlsVal!.statusDeleteTime!.split(" min")[0]);
    // log("userISS :${user["id"]}");
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(user["id"])
        .collection(collectionName.status)
        .get()
        .then((statusesSnapshot) async {
      log("statusesSnapshot.docs.isNotEmpty :${statusesSnapshot.docs}");
      final time = DateTime.now().millisecondsSinceEpoch.toString();
      DateTime expiry =
      appCtrl.usageControlsVal!.statusDeleteTime!.contains(" hrs")
          ? DateTime.now().add(Duration(hours: minHrs))
          : DateTime.now().add(Duration(minutes: minHrs));
      final exp = expiry.millisecondsSinceEpoch.toString();
      if (statusesSnapshot.docs.isNotEmpty) {
        Status status = Status.fromJson(statusesSnapshot.docs[0].data());
        statusImageUrls = status.photoUrl!;

        log("DATTTTT : ${appCtrl.usageControlsVal!.statusDeleteTime!.contains(" hrs") ? DateTime.now().add(Duration(hours: minHrs)) : DateTime.now().add(Duration(minutes: minHrs))}");

        var data = {
          "image": statusType == StatusType.text.name ? "" : imageUrl!,
          "timestamp": time,
          "isExpired": false,
          "statusType": statusType,
          "statusText": statusText,
          "statusBgColor": statusBgColor,
          "expiryDate": exp,
        };
        log("DATAAA : ${user["id"]}");

        statusImageUrls.add(PhotoUrl.fromJson(data));
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(user["id"])
            .collection(collectionName.status)
            .doc(statusesSnapshot.docs[0].id)
            .update({
          'photoUrl': statusImageUrls.map((e) => e.toJson()).toList(),
          "updateAt": time
        }).then((value) {
          final statusCtrl = Get.find<StatusController>();
          statusCtrl.isLoading = false;
          statusCtrl.update();
          appCtrl.isLoading = false;
          appCtrl.update();
        });
        log("jdhfhjdf");

        return;
      } else {
        var data = {
          "image": statusType == StatusType.text.name ? "" : imageUrl!,
          "timestamp": time,
          "isExpired": false,
          "statusType": statusType,
          "statusText": statusText,
          "statusBgColor": statusBgColor,
          "expiryDate": exp
        };
        log("DATAAAtext : $data");
        statusImageUrls = [PhotoUrl.fromJson(data)];
      }

      Status status = Status(
          username: user["name"],
          phoneNumber: user["phone"],
          photoUrl: statusImageUrls,
          createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
          updateAt: DateTime.now().millisecondsSinceEpoch.toString(),
          profilePic: user["image"],
          uid: user["id"],
          isSeenByOwn: false);

      await FirebaseFirestore.instance
          .collection(collectionName.users)
          .doc(user["id"])
          .collection(collectionName.status)
          .add(status.toJson())
          .then((value) {
        log("Status published successfully to: /users/${user['id']}/status/${value.id}");
        log("Status data: ${status.toJson()}");
        final statusCtrl = Get.find<StatusController>();
        statusCtrl.getCurrentStatus();
        statusCtrl.isLoading = false;
        statusCtrl.update();
        Get.forceAppUpdate();
      });
    });
  }
  //get status list
    List<Status> getStatusUserList(List<Contact> contacts,
      QuerySnapshot<Map<String, dynamic>> statusesSnapshot) {
    var user = appCtrl.storage.read(session.user);
    List<Status> statusData = [];
    statusesSnapshot.docs.asMap().entries.forEach((element) {
      int i = contacts.indexWhere((contactList) {
        if (contactList.phones.isNotEmpty) {
          return (contactList.phones.isNotEmpty);
        } else {
          return false;
        }
      });
      debugPrint("i :$i");
      if (i > 0) {
        if (element.value.data()["uid"] != user["id"]) {
          Status tempStatus = Status.fromJson(element.value.data());
          if (!statusData.contains(tempStatus)) {
            statusData.add(tempStatus);
          }
        }
      }
    });

    appCtrl.storage.write(session.statusList, statusData);
    log("statusData : $statusData");

    return statusData;
  }
}
