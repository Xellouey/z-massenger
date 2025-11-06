import 'package:chatzy/screens/bottom_screens/message/layout/receiver_message_card.dart';

import '../../../../config.dart';
import 'broadcast_card.dart';
import 'group_message_card.dart';
import 'message_card.dart';

class LoadUser extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>>? document;
  final String? currentUserId;
  final String? blockBy;

  const LoadUser({super.key, this.document, this.currentUserId, this.blockBy});

  @override
  Widget build(BuildContext context) {
    if (document == null) {
      return Container();
    }

    return GetBuilder<DashboardController>(
      builder: (dash) {
        final data = document?.data();
        if (data == null) {
          return Container();
        }
        
        final isGroup = data['isGroup'] as bool? ?? false;
        final isBroadcast = data['isBroadcast'] as bool? ?? false;
        final senderId = data['senderId'] as String?;
        final currentUserIdStr = appCtrl.user?['id'] as String? ?? '';

        if (!isGroup && !isBroadcast) {
          if (senderId == currentUserIdStr) {
            return ReceiverMessageCard(
              onLongPress: () {
                dash.isLongPress = !dash.isLongPress;
                dash.update();
              },
              onTap: () {
                if (dash.isLongPress) {
                  if (!dash.selectedChat.contains(document!.id)) {
                    dash.selectedChat.add(document!.id);
                  } else {
                    dash.selectedChat.remove(document!.id);
                  }
                  dash.update();
                }
              },
              isLongPress: dash.isLongPress,
              isAvailable: dash.selectedChat.contains(document!.id),
              document: document!,
              currentUserId: currentUserIdStr,
              blockBy: currentUserIdStr,
            ).marginOnly(bottom: Insets.i12);
          } else {
            return MessageCard(
              onLongPress: () {
                dash.isLongPress = !dash.isLongPress;
                dash.update();
              },
              onTap: () {
                if (dash.isLongPress) {
                  if (!dash.selectedChat.contains(document!.id)) {
                    dash.selectedChat.add(document!.id);
                  } else {
                    dash.selectedChat.remove(document!.id);
                  }
                  dash.update();
                }
              },
              isLongPress: dash.isLongPress,
              isAvailable: dash.selectedChat.contains(document!.id),
              blockBy: currentUserIdStr,
              document: document!,
              data: document!,
              currentUserId: currentUserIdStr,
            ).marginOnly(bottom: Insets.i12);
          }
        } else if (isGroup) {
          return GroupMessageCard(
            document: document!,
            onLongPress: () {
              dash.isLongPress = !dash.isLongPress;
              dash.update();
            },
            onTap: () {
              if (dash.isLongPress) {
                if (!dash.selectedChat.contains(document!.id)) {
                  dash.selectedChat.add(document!.id);
                } else {
                  dash.selectedChat.remove(document!.id);
                }
                dash.update();
              }
            },
            currentUserId: currentUserIdStr,
            isLongPress: dash.isLongPress,
            isAvailable: dash.selectedChat.contains(document!.id),
          ).marginOnly(bottom: Insets.i12);
        } else if (isBroadcast) {
          return senderId == appCtrl.user?['id']
              ? BroadCastMessageCard(
            document: document!,
            isLongPress: dash.isLongPress,
            isAvailable: dash.selectedChat.contains(document!.id),
            onLongPress: () {
              dash.isLongPress = !dash.isLongPress;
              dash.update();
            },
            onTap: () {
              if (dash.isLongPress) {
                if (!dash.selectedChat.contains(document!.id)) {
                  dash.selectedChat.add(document!.id);
                } else {
                  dash.selectedChat.remove(document!.id);
                }
                dash.update();
              }
            },
            currentUserId: currentUserIdStr,
          ).marginOnly(bottom: Insets.i12)
              : MessageCard(
            onLongPress: () {
              dash.isLongPress = !dash.isLongPress;
              dash.update();
            },
            onTap: () {
              if (dash.isLongPress) {
                if (!dash.selectedChat.contains(document!.id)) {
                  dash.selectedChat.add(document!.id);
                } else {
                  dash.selectedChat.remove(document!.id);
                }
                dash.update();
              }
            },
            isLongPress: dash.isLongPress,
            isAvailable: dash.selectedChat.contains(document!.id),
            document: document!,
            data: document!,
            currentUserId: currentUserIdStr,
            blockBy: currentUserIdStr,
          ).marginOnly(bottom: Insets.i12);
        }
        return Container();
      },
    );
  }
}


// import 'package:chatzy/screens/bottom_screens/message/layout/receiver_message_card.dart';
//
// import '../../../../config.dart';
// import 'broadcast_card.dart';
// import 'group_message_card.dart';
// import 'message_card.dart';
//
// class LoadUser extends StatelessWidget {
//   final QueryDocumentSnapshot<Map<String, dynamic>>? document;
//   final String? currentUserId, blockBy;
//
//   const LoadUser({super.key, this.document, this.currentUserId, this.blockBy});
//
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<DashboardController>(
//       builder: (dash) {
//         if (document!.data()["isGroup"] == false &&
//             document!.data()["isBroadcast"] == false) {
//           if (document!.data()["senderId"] == appCtrl.user["id"]) {
//             return ReceiverMessageCard(
//                     onLongPress: () async {
//                       if (dash.isLongPress == true) {
//                         dash.isLongPress = false;
//                       } else {
//                         dash.isLongPress = true;
//                       }
//                       dash.update();
//                     },
//                     onTap: () {
//                        if (dash.isLongPress) {
//                         if (!dash.selectedChat.contains(document!.id)) {
//
//                           dash.selectedChat.add(document!.id);
//                         } else {
//                           dash.selectedChat.remove(document!.id);
//                         }
//                         dash.update();
//                        }
//                     },
//                     isLongPress: dash.isLongPress,
//                     isAvailable: dash.selectedChat.contains(document!.id),
//                     document: document!,
//                     currentUserId: appCtrl.user["id"],
//                     blockBy: appCtrl.user['id'])
//                 .marginOnly(bottom: Insets.i12);
//           } else {
//             return MessageCard(
//                     onLongPress: () async {
//                       if (dash.isLongPress == true) {
//                         dash.isLongPress = false;
//                       } else {
//                         dash.isLongPress = true;
//                       }
//                       dash.update();
//                     },
//                     onTap: () {
//                       if (!dash.selectedChat.contains(document!.id)) {
//                         print("object123");
//                         dash.selectedChat.add(document!.id);
//                       } else {
//                         print("object1");
//                         dash.selectedChat.remove(document!.id);
//                       }
//                       dash.update();
//                     },
//                     isLongPress: dash.isLongPress,
//                     isAvailable: dash.selectedChat.contains(document!.id),
//                     blockBy: appCtrl.user["id"],
//                     document: document!,
//                     data: document!,
//                     currentUserId: appCtrl.user["id"])
//                 .marginOnly(bottom: Insets.i12);
//           }
//         } else if (document!.data()["isGroup"] == true) {
//           return GroupMessageCard(
//             document: document!,
//             onLongPress: () async {
//               if (dash.isLongPress == true) {
//                 dash.isLongPress = false;
//               } else {
//                 dash.isLongPress = true;
//               }
//               dash.update();
//             },
//             onTap: () {
//               if (!dash.selectedChat.contains(document!.id)) {
//                 dash.selectedChat.add(document!.id);
//               } else {
//                 dash.selectedChat.remove(document!.id);
//               }
//               dash.update();
//             },
//             currentUserId: appCtrl.user["id"],
//             isLongPress: dash.isLongPress,
//             isAvailable: dash.selectedChat.contains(document!.id),
//           ).marginOnly(bottom: Insets.i12);
//         } else if (document!.data()["isBroadcast"] == true) {
//           return document!.data()["senderId"] == appCtrl.user["id"]
//               ? BroadCastMessageCard(
//                   document: document!,
//                   isLongPress: dash.isLongPress,
//                   isAvailable: dash.selectedChat.contains(document!.id),
//                   onLongPress: () async {
//                     if (dash.isLongPress == true) {
//                       dash.isLongPress = false;
//                     } else {
//                       dash.isLongPress = true;
//                     }
//                     dash.update();
//                   },
//                   onTap: () {
//                     if (!dash.selectedChat.contains(document!.id)) {
//                       dash.selectedChat.add(document!.id);
//                     } else {
//                       dash.selectedChat.remove(document!.id);
//                     }
//                     dash.update();
//                   },
//                   currentUserId: appCtrl.user["id"],
//                 ).marginOnly(bottom: Insets.i12)
//               : MessageCard(
//                       onLongPress: () async {
//                         if (dash.isLongPress == true) {
//                           dash.isLongPress = false;
//                         } else {
//                           dash.isLongPress = true;
//                         }
//                         dash.update();
//                       },
//                       onTap: () {
//                         if (dash.isLongPress) {
//                           if (!dash.selectedChat.contains(document!.id)) {
//                             print("object id");
//                             dash.selectedChat.add(document!.id);
//                           } else {
//                             print("object id 1123");
//                             dash.selectedChat.remove(document!.id);
//                           }
//                           dash.update();
//                         }
//                       },
//                       isLongPress: dash.isLongPress,
//                       isAvailable: dash.selectedChat.contains(document!.id),
//                       document: document!,
//                       currentUserId: appCtrl.user["id"],
//                       data: document!,
//                       blockBy: appCtrl.user["id"])
//                   .marginOnly(bottom: Insets.i12);
//         } else {
//           return Container();
//         }
//       },
//     );
//   }
// }
