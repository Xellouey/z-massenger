import 'dart:developer';
import 'package:chatzy/models/vklm.dart';
import 'package:chatzy/screens/bottom_screens/message/layout/sub_title_layout.dart';
import 'package:chatzy/screens/bottom_screens/message/layout/trailing_layout.dart';
import 'package:chatzy/utils/snack_and_dialogs_utils.dart';
import 'package:flutter/services.dart';
import '../../../../config.dart';
import 'image_layout.dart';

class ReceiverMessageCard extends StatelessWidget {
  final DocumentSnapshot? document;
  final String? currentUserId, blockBy;
  final GestureLongPressCallback? onLongPress;
  final bool isAvailable, isLongPress,isForwardList;
  final GestureTapCallback? onTap;

  const ReceiverMessageCard(
      {super.key,
      this.currentUserId,
      this.blockBy,
      this.isForwardList=false,
      this.document,
      this.onLongPress,
      this.isAvailable = false,
      this.isLongPress = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatDashController>(builder: (msgCtrl) {

      return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection(collectionName.users)
              .doc(document!["receiverId"])
              .snapshots(),
          builder: (context, snapshot) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                        Row(children: [
                          if (isLongPress)
                            Container(
                              height: Sizes.s20,width: Sizes.s20,
                              decoration: ShapeDecoration(
                                  color: isAvailable
                                      ? appCtrl.appTheme.primary
                                      : appCtrl.appTheme.white,
                                  shape:SmoothRectangleBorder(
                                    side: BorderSide(
                                      color: isAvailable? appCtrl.appTheme.primary: appCtrl.appTheme.greyText.withOpacity(.15)
                                    ),
                                      borderRadius: SmoothBorderRadius(
                                          cornerRadius: 4,cornerSmoothing: 1
                                      )
                                  ) ),
                              child: isAvailable? SvgPicture.asset(eSvgAssets.tick1):null,
                            ).inkWell(onTap: onTap),
                          if (isLongPress)
                             const HSpace(Sizes.s18),
                          ImageLayout(
                              id: (snapshot.hasData &&
                                      snapshot.data!.exists &&
                                      snapshot.data!.data() != null)
                                  ? snapshot.data!['id']
                                  : document!['receiverId']),
                          const HSpace(Sizes.s12),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(document!['name'] ?? "",
                                    style: AppCss.manropeblack14
                                        .textColor(appCtrl.appTheme.darkText)),
                                if(isForwardList!=true)
                                const VSpace(Sizes.s5),
                                if(isForwardList!=true)
                                document!["lastMessage"] != null &&
                                        document!["lastMessage"] != ""
                                    ? SubTitleLayout(
                                        document: document,
                                        name: document!['name'],
                                        blockBy: blockBy)
                                    : Container()
                              ])
                        ]),
                            if(isForwardList!=true)
                              TrailingLayout(
                                document: document,
                                currentUserId: currentUserId)

                      ])
                      .width(MediaQuery.of(context).size.width)
                      .paddingOnly(
                          left: Insets.i10,
                          bottom: Insets.i12,
                          right: Insets.i10)
                      .inkWell(
                          onLongPress: onLongPress,
                          onTap: () async {
                            if(isLongPress){
                              onTap!;
                            }else {
                              await Future.delayed(DurationsClass.ms150);
                              log("snapshot.data!:${appCtrl.user['id']}");
                              UserContactModel userContact = UserContactModel(
                                  username: document!["name"],
                                  uid: document!["receiverId"],
                                  phoneNumber: snapshot.data!["phone"] != null
                                      ? snapshot.data!['phone']
                                      : "",
                                  image: snapshot.data!["image"],
                                  isRegister: true);
                              var data = {
                                "chatId": document!["chatId"],
                                "data": userContact
                              };

                              log("message=-=-=-==-=-=-=-=-${data.length}");
                              log("ISCONTAIN : ${(document!.data() as Map<String,dynamic>).containsKey('isLock') }");
                              if((document!.data() as Map<String,dynamic>).containsKey('isLock') ){
                                log("document!['isLock'] :${document!['isLock']}");
                                if(document!['isLock'] == false){
                                  log("hello");
                                  Get.toNamed(
                                      routeName.chatLayout, arguments: data);

                                }else{
                                  bool isAuth = await msgCtrl.authenticate();
                                  if(isAuth){
                                    log("hello12");
                                    Get.toNamed(
                                        routeName.chatLayout, arguments: data);
                                  }else{
                                    snackBar("Failed to Authenticate");
                                  }
                                }
                              }else {
                                log("hello23");
                                Get.toNamed(
                                    routeName.chatLayout, arguments: data);
                              }
                              final chatCtrl = Get.isRegistered<ChatController>()
                                  ? Get.find<ChatController>()
                                  : Get.put(ChatController());
                              chatCtrl.onReady();
                            }
                          }),
                  Divider(
                    height: 0,
                    color: appCtrl.appTheme.borderColor,
                    thickness: 1,
                  ).paddingSymmetric(horizontal: Insets.i10)
                ]).inkWell(onLongPress: onLongPress);
          });
    });
  }



}

