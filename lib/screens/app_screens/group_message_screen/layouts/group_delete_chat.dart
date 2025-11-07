import 'dart:developer';

import '../../../../config.dart';

class GroupDeleteDialog extends StatelessWidget {
  const GroupDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return GetBuilder<GroupChatController>(builder: (chatCtrl) {
              return Align(
                  alignment: Alignment.center,
                  child: Container(
                      height: Sizes.s160,
                      margin: const EdgeInsets.symmetric(
                          horizontal: Insets.i10, vertical: Insets.i15),
                      padding: const EdgeInsets.symmetric(
                          horizontal: Insets.i15, vertical: Insets.i15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appFonts.deleteChatId.tr,
                            style: AppCss.manropeblack16
                                .textColor(appCtrl.appTheme.darkText)
                          ),
                          const VSpace(Sizes.s12),
                          Text(
                            appFonts.deleteChatMessage.tr,
                            style: AppCss.manropeMedium16
                                .textColor(appCtrl.appTheme.darkText),
                          ),
                          const VSpace(Sizes.s20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                  child: ButtonCommon(
                                    title: appFonts.cancel.tr,
                                    onTap: () => Get.back(),
                                    style: AppCss.manropeMedium14
                                        .textColor(appCtrl.appTheme.white),
                                  )),
                              const HSpace(Sizes.s10),
                              Expanded(
                                  child: ButtonCommon(
                                      onTap: () async {
                                        Get.back();

                                        // Delete all messages in the group chat
                                        await FirebaseFirestore.instance
                                            .collection(collectionName.users)
                                            .doc(appCtrl.user["id"])
                                            .collection(collectionName.groupMessage)
                                            .doc(chatCtrl.groupId)
                                            .collection(collectionName.chat)
                                            .get()
                                            .then((value) async {
                                          if (value.docs.isNotEmpty) {
                                            value.docs
                                                .asMap()
                                                .entries
                                                .forEach((element) async {
                                              await FirebaseFirestore.instance
                                                  .collection(collectionName.users)
                                                  .doc(appCtrl.user["id"])
                                                  .collection(
                                                  collectionName.groupMessage)
                                                  .doc(chatCtrl.groupId)
                                                  .collection(collectionName.chat)
                                                  .doc(element.value.id)
                                                  .delete();
                                            });
                                          }

                                          // Delete the group chat document itself
                                          await FirebaseFirestore.instance
                                              .collection(collectionName.users)
                                              .doc(appCtrl.user["id"])
                                              .collection(collectionName.chats)
                                              .where("groupId",
                                              isEqualTo: chatCtrl.groupId)
                                              .get()
                                              .then((userGroup) async {
                                            if (userGroup.docs.isNotEmpty) {
                                              await FirebaseFirestore.instance
                                                  .collection(collectionName.users)
                                                  .doc(appCtrl.user["id"])
                                                  .collection(collectionName.chats)
                                                  .doc(userGroup.docs[0].id)
                                                  .delete();
                                            }
                                          });

                                          chatCtrl.localMessage = [];
                                          chatCtrl.update();

                                          // Navigate back to chat list
                                          Get.back();
                                          log("Group chat deleted successfully");
                                        });
                                      },
                                      title: appFonts.deleteChat.tr,
                                      style: AppCss.manropeMedium14
                                          .textColor(appCtrl.appTheme.white))),
                            ],
                          )
                        ],
                      )).decorated(color: appCtrl.appTheme.white,borderRadius: const BorderRadius.all(Radius.circular(AppRadius.r8))).paddingAll(Insets.i20));
            });
          }),
    );
  }
}
