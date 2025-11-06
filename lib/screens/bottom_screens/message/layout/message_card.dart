import 'dart:developer';
import 'package:chatzy/models/vklm.dart';
import 'package:chatzy/screens/bottom_screens/message/layout/sub_title_layout.dart';
import 'package:chatzy/screens/bottom_screens/message/layout/trailing_layout.dart';
import '../../../../config.dart';
import '../../../../utils/snack_and_dialogs_utils.dart';
import 'image_layout.dart';
import 'message_card_sub_title.dart';

class MessageCard extends StatelessWidget {
  final DocumentSnapshot? document;
  final String? currentUserId, blockBy;
  final dynamic data;
  final GestureLongPressCallback? onLongPress;
  final bool isAvailable, isLongPress,isForwardList;
  final GestureTapCallback? onTap;

  const MessageCard(
      {super.key,
      this.document,
      this.currentUserId,
      this.blockBy,
      this.data,
      this.isForwardList=false,
      this.onLongPress,
      this.isAvailable = false,
      this.isLongPress = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatDashController>(builder: (msgCtrl) {
        return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection(collectionName.users)
                .doc(document!["senderId"])
                .snapshots(),
            builder: (context, snapshot) {
            //  log("snapshot!.data::${data}");
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start,
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
                            const HSpace(20),
                          ImageLayout(id: document!["senderId"]),
                          const HSpace(Sizes.s12),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    (data["name"] != null)
                                        ? data["name"]
                                        : document!['name'],
                                    style: AppCss.manropeblack14
                                        .textColor(appCtrl.appTheme.darkText)),
                                if(isForwardList!=true)
                                const VSpace(Sizes.s6),
                                if(isForwardList!=true)
                                data!["lastMessage"] != null
                                    ? data!["lastMessage"].contains("gif")
                                        ? const Icon(Icons.gif_box)
                                        : MessageCardSubTitle(
                                            data: data,
                                            blockBy: blockBy,
                                            name: document!["name"],
                                            document: document,
                                            currentUserId: currentUserId)
                                    : Container()
                              ])
                        ]),
                        if(isForwardList!=true)
                        TrailingLayout(
                                currentUserId: currentUserId, document: document)

                      ])
                      .width(MediaQuery.of(context).size.width)
                      .paddingOnly(
                          left: Insets.i10, right: Insets.i10, bottom: Insets.i12)

                      .inkWell(onTap: () async{
                        if(isLongPress){
                          onTap!;
                        }else {
                          UserContactModel userContact = UserContactModel(
                              username: (snapshot.hasData &&
                                  snapshot.data!.exists &&
                                  snapshot.data!.data() != null)
                                  ? snapshot.data!.data()!["name"]
                                  : document!["name"],
                              uid: document!["senderId"],
                              phoneNumber: (snapshot.hasData &&
                                  snapshot.data!.exists &&
                                  snapshot.data!.data() != null)
                                  ? snapshot.data!["phone"]
                                  : "",
                              image:
                              snapshot.data != null && snapshot.data!.data() != null
                                  ? snapshot.data!["image"]
                                  : "",
                              isRegister: true);

                          var data = {
                            "chatId": document!["chatId"],
                            "data": userContact
                          };
                          log("SENDER MESSAGE CARD: $data");
                          if((document!.data() as Map<String,dynamic>).containsKey('isLock') ){
                            log("document!['isLock'] :${document!['isLock']}");
                            if(document!['isLock'] == false){
                              Get.toNamed(
                                  routeName.chatLayout, arguments: data);
                            }else{
                              bool isAuth = await msgCtrl.authenticate();
                              if(isAuth){
                                Get.toNamed(
                                    routeName.chatLayout, arguments: data);
                              }else{
                                snackBar("Failed to Authenticate");
                              }
                            }
                          }else {

                            Get.toNamed(
                                routeName.chatLayout, arguments: data);
                          }
                          // final chatCtrl = Get.isRegistered<ChatController>()
                          //     ? Get.find<ChatController>()
                          //     : Get.put(ChatController());
                          // chatCtrl.onReady();
                        }
                  }),
                  Divider(
                          height: 1,
                          color: appCtrl.appTheme.borderColor,
                          thickness: 1)
                      .marginSymmetric(horizontal: Insets.i10)
                ],
              ).inkWell(onLongPress: onLongPress);
            });
      }
    );
  }
}
