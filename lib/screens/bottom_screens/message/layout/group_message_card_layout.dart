
import 'dart:developer';

import 'package:intl/intl.dart';

import '../../../../config.dart';
import '../../../../widgets/common_image_layout.dart';
import 'group_card_sub_title.dart';

class GroupMessageCardLayout extends StatelessWidget {
  final DocumentSnapshot? document;
  final String? currentUserId;
  final AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>? userSnapShot, snapshot;
  final GestureLongPressCallback? onLongPress;
  final bool isAvailable, isLongPress,isForwardList;
  final GestureTapCallback? onTap;

  const GroupMessageCardLayout({
    super.key,
    this.document,
    this.currentUserId,
    this.userSnapShot,
    this.snapshot,
    this.onLongPress,
    this.isForwardList=false,
    this.isAvailable = false,
    this.isLongPress = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (isLongPress)
                  Container(
                    height: Sizes.s20,
                    width: Sizes.s20,
                    decoration: ShapeDecoration(
                      color: isAvailable ? appCtrl.appTheme.primary : appCtrl.appTheme.white,
                      shape: SmoothRectangleBorder(
                        side: BorderSide(
                          color: isAvailable
                              ? appCtrl.appTheme.primary
                              : appCtrl.appTheme.greyText.withOpacity(.15),
                        ),
                        borderRadius: SmoothBorderRadius(cornerRadius: 4, cornerSmoothing: 1),
                      ),
                    ),
                    child: isAvailable ? SvgPicture.asset(eSvgAssets.tick1) : null,
                  ).inkWell(onTap: onTap),
                if (isLongPress) const HSpace(20),
                CommonImage(
                  image: (snapshot!.hasData && snapshot!.data!.exists && snapshot!.data!.data() != null)
                      ? (snapshot!.data!)["image"]
                      : "",
                  name: (snapshot!.hasData && snapshot!.data!.exists && snapshot!.data!.data() != null)
                      ? (snapshot!.data!)["name"]
                      : document!['name'],
                ),

                const HSpace(Sizes.s12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document!['name'],
                      style: AppCss.manropeblack14.textColor(appCtrl.appTheme.darkText),
                    ),
                    if(isForwardList!=true)
                    const VSpace(Sizes.s5),
                    if(isForwardList!=true)
                    document!["lastMessage"] != null
                        ? GroupCardSubTitle(
                      currentUserId: currentUserId,
                      name: (userSnapShot!.hasData &&
                          userSnapShot!.data!.exists &&
                          userSnapShot!.data!.data() != null)
                          ? userSnapShot!.data!["name"]
                          : "",
                      document: document,
                      hasData: userSnapShot!.hasData,
                    )
                        : Container(height: Sizes.s15),
                  ],
                ),
              ],
            ),
            if(isForwardList!=true)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(collectionName.users)
                  .doc(appCtrl.user["id"])
                  .collection(collectionName.groupMessage)
                  .doc(document!["groupId"])
                  .collection(collectionName.chat)
                  .orderBy("timestamp", descending: true) // Order by timestamp
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
                if (snapshot.hasError) {
                  log("Snapshot error: ${snapshot.error}");
                  return Container();
                }
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  int number = getGroupUnseenMessagesNumber(snapshot.data!.docs);
                  //log("Group unseen message count: $number");
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            int.parse(document!['updateStamp']),
                          ),
                        ),
                        style: AppCss.manropeMedium12.textColor(
                          currentUserId == document!["senderId"]
                              ? appCtrl.appTheme.darkText
                              : number == 0
                              ? appCtrl.appTheme.darkText
                              : appCtrl.appTheme.primary,
                        ),
                      ),
                      if (appCtrl.user["id"] != document!["senderId"] && number > 0)
                        Container(
                          height: Sizes.s20,
                          width: Sizes.s20,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(top: Insets.i5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                appCtrl.appTheme.primary,
                                appCtrl.appTheme.primary,
                              ],
                            ),
                          ),
                          child: Text(
                            number.toString(),
                            textAlign: TextAlign.center,
                            style: AppCss.manropeBold10
                                .textColor(appCtrl.appTheme.sameWhite)
                                .textHeight(1.3),
                          ),
                        ),
                    ],
                  );
                } else {
                  log("No data in snapshot or empty docs");
                  return Container();
                }
              },
            ),
          ],
        ).paddingSymmetric(vertical: Insets.i10),
        Divider(height: 1, color: appCtrl.appTheme.borderColor, thickness: 1)
            .paddingSymmetric(horizontal: Insets.i10),
      ],
    );
  }

  int getGroupUnseenMessagesNumber(List<QueryDocumentSnapshot<Map<String, dynamic>>> items) {
    int groupCounter = 0;
    for (var element in items) {
      final data = element.data();

      // Skip messages sent by the current user
      if (data["sender"] == appCtrl.user["id"]) {
        continue;
      }

      // Check if seenMessageList exists and is a list
      if (!data.containsKey("seenMessageList") || data["seenMessageList"] == null) {
        groupCounter++;

        continue;
      }

      // Ensure seenMessageList is a List and check if current user has seen the message
      if (data["seenMessageList"] is List && data["seenMessageList"].contains(appCtrl.user["id"])) {
        groupCounter++;

      } else {
       // log("Message seen by user or invalid seenMessageList: ${element.id}");
      }
    }
    // log("Total unseen messages: $groupCounter");
    return groupCounter;
  }
}

// import 'dart:developer';
//
// import 'package:intl/intl.dart';
// import '../../../../config.dart';
// import '../../../../widgets/common_image_layout.dart';
// import 'group_card_sub_title.dart';
//
// class GroupMessageCardLayout extends StatelessWidget {
//   final DocumentSnapshot? document;
//   final String? currentUserId;
//   final AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>? userSnapShot,
//       snapshot;
//   final GestureLongPressCallback? onLongPress;
//   final bool isAvailable, isLongPress;
//   final GestureTapCallback? onTap;
//
//   const GroupMessageCardLayout(
//       {super.key,
//         this.document,
//         this.currentUserId,
//         this.userSnapShot,
//         this.snapshot, this.onLongPress,
//         this.isAvailable = false,
//         this.isLongPress = false,
//         this.onTap})
//   ;
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Column(
//       children: [
//         Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(children: [
//                 if (isLongPress)
//                   Container(
//                     height: Sizes.s20,width: Sizes.s20,
//                     decoration: ShapeDecoration(
//                         color: isAvailable
//                             ? appCtrl.appTheme.primary
//                             : appCtrl.appTheme.white,
//                         shape:SmoothRectangleBorder(
//                             side: BorderSide(
//                                 color: isAvailable? appCtrl.appTheme.primary: appCtrl.appTheme.greyText.withOpacity(.15)
//                             ),
//                             borderRadius: SmoothBorderRadius(
//                                 cornerRadius: 4,cornerSmoothing: 1
//                             )
//                         ) ),
//                     child: isAvailable? SvgPicture.asset(eSvgAssets.tick1):null,
//                   ).inkWell(onTap: onTap),
//                 if (isLongPress)
//                   const HSpace(20),
//                 CommonImage(
//                     image:( snapshot!.hasData && snapshot!.data!.exists && snapshot!.data!.data() != null )? (snapshot!.data!)["image"]:"",
//                     name:( snapshot!.hasData && snapshot!.data!.exists && snapshot!.data!.data() != null )?  (snapshot!.data!)["name"]:document!['name']),
//                 const HSpace(Sizes.s12),
//                 Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                   Text(document!['name'],
//                       style: AppCss.manropeblack14
//                           .textColor(appCtrl.appTheme.darkText)),
//                   const VSpace(Sizes.s5),
//                   document!["lastMessage"] != null
//                       ? GroupCardSubTitle(
//                       currentUserId: currentUserId,
//                       name:( userSnapShot!.hasData && userSnapShot!.data!.exists && userSnapShot!.data!.data() != null )?  userSnapShot!.data!["name"]:"",
//                       document: document,
//                       hasData: userSnapShot!.hasData)
//                       : Container(height: Sizes.s15)
//                 ])
//               ]),
//               StreamBuilder(
//                   stream: FirebaseFirestore.instance
//                       .collection(collectionName.groups)
//                       .doc(document!["groupId"])
//                       .collection(collectionName.chat)
//                       .snapshots(),
//                   builder: (context, snapshot) {
//                     if (snapshot.hasData) {
//                       int number = getGroupUnseenMessagesNumber(snapshot.data!.docs);
//                       return Column(
//                         children: [
//                           Text(
//                               DateFormat('HH:mm').format(
//                                   DateTime.fromMillisecondsSinceEpoch(
//                                       int.parse(document!['updateStamp']))),
//                               style: AppCss.manropeMedium12
//                                   .textColor(currentUserId == document!["senderId"]
//                                   ? appCtrl.appTheme.darkText
//                                   : number == 0
//                                   ? appCtrl.appTheme.darkText
//                                   : appCtrl.appTheme.primary)),
//                           if ((currentUserId != document!["senderId"]))
//                             number == 0
//                                 ? Container()
//                                 : Container(
//                                 height: Sizes.s20,
//                                 width: Sizes.s20,
//                                 alignment: Alignment.center,
//                                 margin: const EdgeInsets.only(top: Insets.i5),
//                                 decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     gradient: RadialGradient(
//                                       colors: [
//                                         appCtrl.appTheme.primary,
//                                         appCtrl.appTheme.primary
//                                       ],
//                                     )),
//                                 child: Text(number.toString(),
//                                     textAlign: TextAlign.center,
//                                     style: AppCss.manropeBold10
//                                         .textColor(appCtrl.appTheme.sameWhite)
//                                         .textHeight(1.3))),
//                         ],
//                       );
//                     } else {
//                       return Container();
//                     }
//                   })
//             ]).paddingSymmetric(vertical: Insets.i10),
//         Divider(height: 1,color: appCtrl.appTheme.borderColor,thickness: 1).paddingSymmetric(horizontal: Insets.i10)
//       ],
//     );
//   }
// }
