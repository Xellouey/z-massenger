import 'dart:developer';

import '../../../../config.dart';
import '../../../../utils/snack_and_dialogs_utils.dart';
import 'group_message_card_layout.dart';

class GroupMessageCard extends StatelessWidget {
  final DocumentSnapshot? document;
  final String? currentUserId;
  final GestureLongPressCallback? onLongPress;
  final bool isAvailable, isLongPress,isForwardList;
  final GestureTapCallback? onTap;

  const GroupMessageCard(
      {super.key,
      this.document,
      this.currentUserId,
      this.onLongPress,
      this.isForwardList=false,
      this.isAvailable = false,
      this.isLongPress = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatDashController>(builder: (msgCtrl) {
      return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection(collectionName.groups)
              .doc(document!["groupId"])
              .snapshots(),
          builder: (context, snapshot) {
            return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .doc(document!["senderId"])
                        .snapshots(),
                    builder: (context, userSnapShot) {
                      return GroupMessageCardLayout(
                        isForwardList:isForwardList,
                        snapshot: snapshot,
                        document: document,
                        currentUserId: currentUserId,
                        userSnapShot: userSnapShot,
                        onTap: onTap,
                        isAvailable: isAvailable,
                        isLongPress: isLongPress,
                        onLongPress: onLongPress,
                      ).inkWell(onTap: () async {
                        if (isLongPress) {
                          onTap!;
                        } else {
                          if(snapshot.data?.data()!=null){
                          var data = {
                            "message": document!.data(),
                            "groupData": snapshot.data!.data()
                          };
                          log("document!['isLock'] :${data}");

                          if ((document!.data() as Map<String, dynamic>)
                              .containsKey('isLock')) {

                            if (document!['isLock'] == false) {
                              Get.toNamed(routeName.groupChatMessage,
                                  arguments: data);
                            } else {
                              bool isAuth = await msgCtrl.authenticate();
                              if (isAuth) {
                                Get.toNamed(routeName.groupChatMessage,
                                    arguments: data);
                              } else {
                                snackBar("Failed to Authenticate");
                              }
                            }
                          } else {
                            log("CCCCCC");

                            Get.toNamed(routeName.groupChatMessage,
                                arguments: data);

                          }}else{snackBar("Something wants wrong Please wait");}
                        }
                      });
                    })
                .width(MediaQuery.of(context).size.width)
                .paddingSymmetric(horizontal: Insets.i10, vertical: Insets.i4)
                .inkWell(onLongPress: onLongPress);
          });
    });
  }
}
