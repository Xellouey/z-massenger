import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatzy/controllers/common_controllers/contact_controller.dart';

import 'package:chatzy/screens/bottom_screens/message/layout/load_user.dart';
import '../../../../config.dart';
import '../../../../controllers/recent_chat_controller.dart';

class ChatCard extends StatefulWidget {
  const ChatCard({super.key});

  @override
  State<ChatCard> createState() => _ChatCardState();
}

class _ChatCardState extends State<ChatCard> {
  final scrollController = ScrollController();
  int inviteContactsCount = 30;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(scrollListener);


    final recentChat = Provider.of<RecentChatController>(context, listen: false);
    recentChat.getMessageList(); // Make sure this listens to Firestore snapshots
  }

  void scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent / 2 &&
        !scrollController.position.outOfRange) {
      setStateIfMounted(() {
        inviteContactsCount += 250;
      });
    }
  }

  void setStateIfMounted(VoidCallback fn) {
    if (mounted) fn();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashboardController>(builder: (dashboardCtrl) {
      return Consumer<RecentChatController>(builder: (context, recentChat, child) {
        return recentChat.messageList.isNotEmpty
            ? ListView.builder(
          controller: scrollController,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentChat.messageList.length,
          itemBuilder: (context, index) {
            return LoadUser(document: recentChat.messageList[index]);
          },
        ).paddingSymmetric(vertical: Insets.i20, horizontal: Insets.i10)
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Image.asset(eImageAssets.noChat, height: Sizes.s150),
    Text(appFonts.noChat.tr,
            style: AppCss.manropeBold16
                .textColor(appCtrl.appTheme.darkText))
        .paddingSymmetric(vertical: Insets.i10),
    Text(appFonts.thereIsNoChat.tr,
        textAlign: TextAlign.center,
        style: AppCss.manropeMedium14
            .textColor(appCtrl.appTheme.greyText)
            .textHeight(1.5))
  ])
    .paddingSymmetric(horizontal: Insets.i20)
    .alignment(Alignment.center);
        /*ListView.builder(
          itemCount: 3,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return const CategoryShimmer();
          },
        );*/
      });
    });
  }
}



// import 'package:chatzy/screens/bottom_screens/chat_shimmer.dart';
// import 'package:chatzy/screens/bottom_screens/message/layout/load_user.dart';
// import '../../../../config.dart';
// import '../../../../controllers/recent_chat_controller.dart';
//
// class ChatCard extends StatefulWidget {
//   const ChatCard({super.key});
//
//   @override
//   State<ChatCard> createState() => _ChatCardState();
// }
//
// class _ChatCardState extends State<ChatCard> {
//   final messageCtrl = Get.isRegistered<ChatDashController>()
//       ? Get.find<ChatDashController>()
//       : Get.put(ChatDashController());
//
//   final scrollController = ScrollController();
//   int inviteContactsCount = 30;
//   bool isLoading = true;
//   Stream? stream;
//
//   @override
//   void initState() {
//     super.initState();
//     stream = FirebaseFirestore.instance
//         .collection(collectionName.users)
//         .doc(appCtrl.user["id"])
//         .collection(collectionName.chats)
//         .snapshots();
//     scrollController.addListener(scrollListener);
//   }
//
//   String? sharedSecret;
//   String? privateKey;
//
//   void scrollListener() {
//     if (scrollController.offset >=
//             scrollController.position.maxScrollExtent / 2 &&
//         !scrollController.position.outOfRange) {
//       setStateIfMounted(() {
//         inviteContactsCount = inviteContactsCount + 250;
//       });
//     }
//   }
//
//   void setStateIfMounted(f) {
//     if (mounted) setState(f);
//   }
//
//   @override
//   void dispose() {
//     scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<ChatDashController>(builder: (messageCtrl) {
//       return GetBuilder<DashboardController>(builder: (dashboardCtrl) {
//         return Consumer<RecentChatController>(
//             builder: (context, recentChat, child) {
//           return recentChat.messageList.isNotEmpty
//               ? ListView(
//                   shrinkWrap: true,
//                   controller: scrollController,
//                   children: [
//                       Column(
//                         children: [
//                           ...recentChat.messageList
//                               .asMap()
//                               .entries
//                               .map((e) => LoadUser(
//                                     document: e.value,
//                                   ))
//                         ],
//                       ).marginSymmetric(
//                           vertical: Insets.i20, horizontal: Insets.i10)
//                     ])
//               :
//           ListView.builder(
//               itemCount: 3,
//               physics: NeverScrollableScrollPhysics(),
//               shrinkWrap: true,
//               itemBuilder: (context,index){
//                 return CategoryShimmer();
//           });
//           //  ListView(
//           //     shrinkWrap: true,
//           //     controller: scrollController,
//           //     children: [
//           //       Column(
//           //         children: [
//           //           ...recentChat.messageList
//           //               .asMap()
//           //               .entries
//           //               .map((e) => LoadUser(
//           //             document: e.value,
//           //           ))
//           //         ],
//           //       ).marginSymmetric(
//           //           vertical: Insets.i20, horizontal: Insets.i10)
//           //     ]);
//
//
//               /*Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//                   Image.asset(eImageAssets.noChat, height: Sizes.s150),
//                   Text(appFonts.noChat.tr,
//                           style: AppCss.manropeBold16
//                               .textColor(appCtrl.appTheme.darkText))
//                       .paddingSymmetric(vertical: Insets.i10),
//                   Text(appFonts.thereIsNoChat.tr,
//                       textAlign: TextAlign.center,
//                       style: AppCss.manropeMedium14
//                           .textColor(appCtrl.appTheme.greyText)
//                           .textHeight(1.5))
//                 ])
//                   .paddingSymmetric(horizontal: Insets.i20)
//                   .alignment(Alignment.center);*/
//         });
//       });
//     });
//   }
// }
//
