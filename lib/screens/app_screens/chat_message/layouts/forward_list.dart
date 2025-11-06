/*
import 'dart:developer';

import 'package:chatzy/controllers/common_controllers/contact_controller.dart';
import 'package:chatzy/widgets/common_loader.dart';
import 'package:flutter/cupertino.dart';

import '../../../../config.dart';
import '../../../../widgets/common_image_layout.dart';
import '../../group_message_screen/layouts/all_registered_contact.dart';

class ForwardList extends StatelessWidget {
  const ForwardList({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(builder: (chatCtrl) {
      return Consumer<ContactProvider>(
          builder: (context, availableContacts, child) {
        return PickupLayout(
          scaffold: DirectionalityRtl(
            child: Scaffold(
              backgroundColor: appCtrl.appTheme.white,
              appBar: AppBar(
                  backgroundColor: appCtrl.appTheme.white,
                  elevation: 0,
                  leading: ActionIconsCommon(
                      icon: appCtrl.isRTL || appCtrl.languageVal == "ar"
                          ? eSvgAssets.arrowRight
                          : eSvgAssets.arrowLeft,
                      onTap: () => Get.back(),
                      vPadding: Insets.i8,
                      hPadding: Insets.i8),
                  titleSpacing: 0,
                  title: chatCtrl.isContactSearch
                      ? TextFieldCommon(
                          controller: chatCtrl.searchText,
                          hintText: "Search...",
                          fillColor: appCtrl.appTheme.white,
                          autoFocus: true,
                          border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: appCtrl.appTheme.darkText,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.r8)),
                          keyboardType: TextInputType.multiline,
                          onChanged: (val) {
                            availableContacts.searchUser(val);
                            chatCtrl.searchText.text.isNotEmpty
                                ? Icon(CupertinoIcons.multiply,
                                        color: appCtrl.appTheme.white,
                                        size: Sizes.s15)
                                    .decorated(
                                        color: appCtrl.appTheme.darkText
                                            .withOpacity(.3),
                                        shape: BoxShape.circle)
                                    .marginAll(Insets.i12)
                                    .inkWell(onTap: () {
                                    chatCtrl.isContactSearch = false;
                                    chatCtrl.searchText.text = "";
                                    chatCtrl.update();
                                  })
                                : SvgPicture.asset(eSvgAssets.search,
                                        height: Sizes.s15)
                                    .marginAll(Insets.i12)
                                    .inkWell(onTap: () {
                                    chatCtrl.isContactSearch = false;
                                    chatCtrl.searchText.text = "";
                                    chatCtrl.update();
                                  });
                          },
                        ).marginOnly(right: Sizes.s10)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(appFonts.contact.tr,
                                  style: AppCss.manropeBold16
                                      .textColor(appCtrl.appTheme.darkText)),
                              const VSpace(Sizes.s5),
                              Text(appFonts.addParticipant.tr,
                                  style: AppCss.manropeMedium12
                                      .textColor(appCtrl.appTheme.greyText))
                            ]),
                  actions: [
                    Row(children: [
                      ActionIconsCommon(
                          icon: eSvgAssets.refresh,
                          onTap: () {
                            availableContacts
                                .fetchContacts(appCtrl.user["phone"]);
                            flutterAlertMessage(msg: "Loading..");
                          },
                          vPadding: Insets.i8),
                      const HSpace(Sizes.s10),
                      if (!chatCtrl.isContactSearch)
                        ActionIconsCommon(
                            icon: eSvgAssets.search,
                            onTap: () {
                              chatCtrl.isContactSearch =
                                  !chatCtrl.isContactSearch;
                              chatCtrl.update();
                            },
                            vPadding: Insets.i8,
                            hPadding: Insets.i10)
                    ])
                  ]),
              floatingActionButton: chatCtrl.selectedUser != null
                  ? FloatingActionButton(
                      onPressed: () async {
                        log("chatCtrl.selectedContent:${chatCtrl.selectedContent}");
                        UserContactModel user = UserContactModel(
                            uid: chatCtrl.forwardUser!.id,
                            isRegister: false,
                            image: chatCtrl.forwardUser!.image,
                            username: chatCtrl.forwardUser!.name,
                            phoneNumber: chatCtrl.forwardUser!.phone,
                            description: "");
                        await FirebaseFirestore.instance
                            .collection(collectionName.users)
                            .doc(appCtrl.user['id'])
                            .collection("chats")
                            .where("isOneToOne", isEqualTo: true)
                            .get()
                            .then((value) {
                          log("chatCtrl.selectedUser:${chatCtrl.selectedUser} || ${appCtrl.user['id']}");
                          bool isEmpty = value.docs
                              .where((element) =>
                                  element.data()["senderId"] ==
                                      chatCtrl.selectedUser ||
                                  element.data()["receiverId"] ==
                                      chatCtrl.selectedUser)
                              .isNotEmpty;
                          log("isEmpty:$isEmpty");
                          if (!isEmpty) {
                            log("dff");
                            var data = {
                              "chatId": chatCtrl.selectedUser,
                              "data": user,
                              "forwardMessage": chatCtrl.selectedContent
                            };

                            Get.back();
                            Get.back();
                            log("data :$data//$user");
                            Get.toNamed(routeName.chatLayout,
                                arguments: data, preventDuplicates: false);
                          } else {
                            value.docs.asMap().entries.forEach((element) async {
                              if (element.value.data()["senderId"] ==
                                      chatCtrl.selectedUser ||
                                  element.value.data()["receiverId"] ==
                                      chatCtrl.selectedUser) {
                                log("CHATID:${element.value.data()["chatId"]}");
                                var data = {
                                  "chatId": element.value.data()["chatId"],
                                  "data": user,
                                  "forwardMessage": chatCtrl.selectedContent
                                };
                                Get.back();
                                Get.back();
                                await Future.delayed(Duration(seconds: 1));
                                Get.toNamed(routeName.chatLayout,
                                    arguments: data);
                              }
                            });
                          }
                        });
                      },
                      backgroundColor: appCtrl.appTheme.primary,
                      child: Icon(Icons.arrow_forward_outlined,
                          color: appCtrl.appTheme.sameWhite))
                  : null,
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    if (chatCtrl.searchText.text.isNotEmpty)
                      Column(children: [
                        availableContacts.searchRegisterContact.isNotEmpty
                            ? Column(children: [
                                ...availableContacts.searchRegisterContact
                                    .asMap()
                                    .entries
                                    .map((e) => StreamBuilder(
                                        stream: FirebaseFirestore.instance
                                            .collection(collectionName.users)
                                            .doc(e.value.id)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Column(children: [
                                              Row(children: [
                                                Container(
                                                        decoration: BoxDecoration(
                                                            color: chatCtrl.selectedUser == e.value.id
                                                                ? appCtrl
                                                                    .appTheme
                                                                    .primary
                                                                : appCtrl
                                                                    .appTheme
                                                                    .trans,
                                                            border: Border.all(
                                                                color: chatCtrl.selectedUser == e.value.id!
                                                                    ? appCtrl
                                                                        .appTheme
                                                                        .trans
                                                                    : appCtrl
                                                                        .appTheme
                                                                        .borderColor,
                                                                width: 1),
                                                            borderRadius: BorderRadius.circular(
                                                                5)),
                                                        child: Icon(chatCtrl.selectedUser == e.value.id ? Icons.check : null,
                                                                size: Sizes.s15,
                                                                color: chatCtrl.selectedUser == e.value.id ? appCtrl.appTheme.sameWhite : appCtrl.appTheme.trans)
                                                            .paddingAll(Insets.i2))
                                                    .inkWell(onTap: () {
                                                  chatCtrl.selectedUser =
                                                      e.value.id;
                                                  log("CHHH :${e.value.id} || ${e.value.name}");
                                                  chatCtrl.forwardUser =
                                                      e.value;
                                                  chatCtrl.update();
                                                }),
                                                const HSpace(Sizes.s20),
                                                CommonImage(
                                                    image: snapshot.data!
                                                        .data()!["image"],
                                                    name: e.value.name),
                                                const HSpace(Sizes.s10),
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(e.value.name ?? "",
                                                          style: AppCss
                                                              .manropeBold14
                                                              .textColor(appCtrl
                                                                  .appTheme
                                                                  .darkText)),
                                                      const VSpace(Sizes.s8),
                                                      Text(
                                                          snapshot.data!
                                                                      .data()![
                                                                  "statusDesc"] ??
                                                              "",
                                                          style: AppCss
                                                              .manropeMedium14
                                                              .textColor(appCtrl
                                                                  .appTheme
                                                                  .greyText))
                                                    ])
                                              ]),
                                              Divider(
                                                      height: 1,
                                                      color: appCtrl
                                                          .appTheme.borderColor)
                                                  .paddingSymmetric(
                                                      vertical: Insets.i20)
                                            ]);
                                          } else {
                                            return Container();
                                          }
                                        }))
                              ]).paddingSymmetric(horizontal: Insets.i20)
                            : const CommonLoader()
                      ]),
                    if (chatCtrl.searchText.text.isEmpty)
                      Column(children: [
                        availableContacts.registeredContacts.isNotEmpty
                            ? Column(children: [
                                ...availableContacts.registeredContacts
                                    .asMap()
                                    .entries
                                    .map((e) => StreamBuilder(
                                        stream: FirebaseFirestore.instance
                                            .collection(collectionName.users)
                                            .doc(e.value.id)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Column(children: [
                                              Row(children: [
                                                Container(
                                                        decoration: BoxDecoration(
                                                            color: chatCtrl.selectedUser == e.value.id
                                                                ? appCtrl
                                                                    .appTheme
                                                                    .primary
                                                                : appCtrl
                                                                    .appTheme
                                                                    .trans,
                                                            border: Border.all(
                                                                color: chatCtrl.selectedUser == e.value.id
                                                                    ? appCtrl
                                                                        .appTheme
                                                                        .trans
                                                                    : appCtrl
                                                                        .appTheme
                                                                        .borderColor,
                                                                width: 1),
                                                            borderRadius: BorderRadius.circular(
                                                                5)),
                                                        child: Icon(chatCtrl.selectedUser == e.value.id ? Icons.check : null,
                                                                size: Sizes.s15,
                                                                color: chatCtrl.selectedUser == e.value.id ? appCtrl.appTheme.sameWhite : appCtrl.appTheme.trans)
                                                            .paddingAll(Insets.i2))
                                                    .inkWell(onTap: () {
                                                  chatCtrl.selectedUser =
                                                      e.value.id;
                                                  log("CHHH :${e.value.id} || ${e.value.name}");
                                                  chatCtrl.forwardUser =
                                                      e.value;
                                                  chatCtrl.update();
                                                }),
                                                const HSpace(Sizes.s20),
                                                CommonImage(
                                                    image: snapshot.data!
                                                        .data()!["image"],
                                                    name: e.value.name),
                                                const HSpace(Sizes.s10),
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(e.value.name ?? "",
                                                          style: AppCss
                                                              .manropeBold14
                                                              .textColor(appCtrl
                                                                  .appTheme
                                                                  .darkText)),
                                                      const VSpace(Sizes.s8),
                                                      Text(
                                                          snapshot.data!
                                                                      .data()![
                                                                  "statusDesc"] ??
                                                              "",
                                                          style: AppCss
                                                              .manropeMedium14
                                                              .textColor(appCtrl
                                                                  .appTheme
                                                                  .greyText))
                                                    ])
                                              ]),
                                              Divider(
                                                      height: 1,
                                                      color: appCtrl
                                                          .appTheme.borderColor)
                                                  .paddingSymmetric(
                                                      vertical: Insets.i20)
                                            ]);
                                          } else {
                                            return Container();
                                          }
                                        }))
                              ]).paddingSymmetric(horizontal: Insets.i20)
                            : const CommonLoader()
                      ])
                  ],
                ),
              ),
            ),
          ),
        );
      });
    });
  }
}
*/
import 'dart:developer';

import 'package:flutter/cupertino.dart';

import '../../../../config.dart';
import '../../../../controllers/app_pages_controllers/forward_controller.dart';
import '../../../../controllers/common_controllers/contact_controller.dart';
import '../../../../controllers/recent_chat_controller.dart';
import '../../../../widgets/common_image_layout.dart';
import '../../../../widgets/common_loader.dart';
import '../../../bottom_screens/message/layout/broadcast_card.dart';
import '../../../bottom_screens/message/layout/group_message_card.dart';
import '../../../bottom_screens/message/layout/load_user.dart';
import '../../../bottom_screens/message/layout/message_card.dart';
import '../../../bottom_screens/message/layout/receiver_message_card.dart';
import '../../group_message_screen/layouts/all_registered_contact.dart';

class ForwardList extends StatefulWidget {
  const ForwardList({
    super.key,
  });

  @override
  State<ForwardList> createState() => _ForwardListState();
}

class _ForwardListState extends State<ForwardList> {
  final scrollController = ScrollController();
  int inviteContactsCount = 30;
  ForwardController forwardController = Get.put(ForwardController());

  @override
  void initState() {
    super.initState();
    scrollController.addListener(scrollListener);

  }

  void scrollListener() {
    if (scrollController.offset >=
            scrollController.position.maxScrollExtent / 2 &&
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
    Get.put(ChatController());
    return GetBuilder<ForwardController>(builder: (forCtrl) {
      return GetBuilder<ChatController>(builder: (chatCtrl) {
        return Consumer2<RecentChatController, ContactProvider>(
            builder: (context, recentChat, availableContacts, child) {
          return PickupLayout(
            scaffold: DirectionalityRtl(
              child: Scaffold(
                backgroundColor: appCtrl.appTheme.white,
                appBar: AppBar(
                    backgroundColor: appCtrl.appTheme.white,
                    elevation: 0,
                    leading: ActionIconsCommon(
                        icon: appCtrl.isRTL || appCtrl.languageVal == "ar"
                            ? eSvgAssets.arrowRight
                            : eSvgAssets.arrowLeft,
                        onTap: () => Get.back(),
                        vPadding: Insets.i8,
                        hPadding: Insets.i8),
                    titleSpacing: 0,
                    title: Text("Recent Chats"),
                   ),
                floatingActionButton: forCtrl.forwardData.isNotEmpty
                    ? FloatingActionButton(
                        onPressed: () => forCtrl.sendToAll(),
                        backgroundColor: appCtrl.appTheme.primary,
                        child: Icon(Icons.arrow_forward_outlined,
                            color: appCtrl.appTheme.sameWhite))
                    : null,
                body: forCtrl.isLoading?CommonLoader() : SingleChildScrollView(
                  child: Column(
                    children: [
                      if (chatCtrl.searchText.text.isNotEmpty)
                        Column(children: [
                          availableContacts.searchRegisterContact.isNotEmpty
                              ? Column(children: [
                                  ...availableContacts.searchRegisterContact
                                      .asMap()
                                      .entries
                                      .map((e) => StreamBuilder(
                                          stream: FirebaseFirestore.instance
                                              .collection(collectionName.users)
                                              .doc(e.value.id)
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              return Column(children: [
                                                Row(children: [
                                                  Container(
                                                          decoration: BoxDecoration(
                                                              color: chatCtrl
                                                                          .selectedUser ==
                                                                      e.value.id
                                                                  ? appCtrl
                                                                      .appTheme
                                                                      .primary
                                                                  : appCtrl
                                                                      .appTheme
                                                                      .trans,
                                                              border: Border.all(
                                                                  color: chatCtrl.selectedUser ==
                                                                          e.value
                                                                              .id!
                                                                      ? appCtrl
                                                                          .appTheme
                                                                          .trans
                                                                      : appCtrl
                                                                          .appTheme
                                                                          .borderColor,
                                                                  width: 1),
                                                              borderRadius:
                                                                  BorderRadius.circular(5)),
                                                          child: Icon(chatCtrl.selectedUser == e.value.id ? Icons.check : null, size: Sizes.s15, color: chatCtrl.selectedUser == e.value.id ? appCtrl.appTheme.sameWhite : appCtrl.appTheme.trans).paddingAll(Insets.i2))
                                                      .inkWell(onTap: () {
                                                    chatCtrl.selectedUser =
                                                        e.value.id;
                                                    log("CHHH :${e.value.id} || ${e.value.name}");
                                                    chatCtrl.forwardUser =
                                                        e.value;
                                                    chatCtrl.update();
                                                  }),
                                                  const HSpace(Sizes.s20),
                                                  CommonImage(
                                                      image: snapshot.data!
                                                          .data()!["image"],
                                                      name: e.value.name),
                                                  const HSpace(Sizes.s10),
                                                  Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(e.value.name ?? "",
                                                            style: AppCss
                                                                .manropeBold14
                                                                .textColor(appCtrl
                                                                    .appTheme
                                                                    .darkText)),
                                                        const VSpace(Sizes.s8),
                                                        Text(
                                                            snapshot.data!
                                                                        .data()![
                                                                    "statusDesc"] ??
                                                                "",
                                                            style: AppCss
                                                                .manropeMedium14
                                                                .textColor(appCtrl
                                                                    .appTheme
                                                                    .greyText))
                                                      ])
                                                ]),
                                                Divider(
                                                        height: 1,
                                                        color: appCtrl.appTheme
                                                            .borderColor)
                                                    .paddingSymmetric(
                                                        vertical: Insets.i20)
                                              ]);
                                            } else {
                                              return Container();
                                            }
                                          }))
                                ]).paddingSymmetric(horizontal: Insets.i20)
                              : const CommonLoader()
                        ]),
                      if (chatCtrl.searchText.text.isEmpty)
                        Column(children: [
                          recentChat.messageList.isNotEmpty
                              ? Column(children: [
                                  ListView.builder(
                                      controller: scrollController,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: recentChat.messageList.length,
                                      itemBuilder: (context, index) {
                                        final e = recentChat.messageList[index];

                                        return Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: forCtrl
                                                        .isContain(e.data())
                                                    ? appCtrl.appTheme.primary
                                                    : appCtrl.appTheme.trans,
                                                border: Border.all(
                                                  color: forCtrl
                                                          .isContain(e.data())
                                                      ? appCtrl.appTheme.trans
                                                      : appCtrl
                                                          .appTheme.borderColor,
                                                  width: 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: Icon(
                                                Icons.check,
                                                size: Sizes.s15,
                                                color: forCtrl
                                                        .isContain(e.data())
                                                    ? appCtrl.appTheme.sameWhite
                                                    : appCtrl.appTheme.trans,
                                              ).paddingAll(Insets.i2),
                                            ).inkWell(
                                              onTap: () {
                                                // chatCtrl.forwardUser = e;
                                                forCtrl
                                                    .forwardDataTap(e.data());
                                                chatCtrl.update();
                                              },
                                            ),
                                            Expanded(child:
                                                GetBuilder<DashboardController>(
                                              builder: (dash) {
                                                final data = recentChat
                                                    .messageList[index];
                                                final isGroup =
                                                    data['isGroup'] as bool? ??
                                                        false;
                                                final isBroadcast =
                                                    data['isBroadcast']
                                                            as bool? ??
                                                        false;
                                                final senderId =
                                                    data['senderId'] as String?;

                                                if (!isGroup && !isBroadcast) {
                                                  if (senderId ==
                                                      appCtrl.user?['id']) {
                                                    return ReceiverMessageCard(
                                                      isForwardList: true,
                                                      onLongPress: () {
                                                        dash.isLongPress =
                                                            !dash.isLongPress;
                                                        dash.update();
                                                      },
                                                      onTap: () {
                                                        if (dash.isLongPress) {
                                                          if (!dash.selectedChat
                                                              .contains(recentChat
                                                                  .messageList[
                                                                      index]!
                                                                  .id)) {
                                                            dash.selectedChat
                                                                .add(recentChat
                                                                    .messageList[
                                                                        index]!
                                                                    .id);
                                                          } else {
                                                            dash.selectedChat
                                                                .remove(recentChat
                                                                    .messageList[
                                                                        index]!
                                                                    .id);
                                                          }
                                                          dash.update();
                                                        }
                                                      },
                                                      // isLongPress: dash.isLongPress,
                                                      isAvailable: dash
                                                          .selectedChat
                                                          .contains(recentChat
                                                              .messageList[
                                                                  index]!
                                                              .id),
                                                      document: recentChat
                                                          .messageList[index]!,
                                                      currentUserId:
                                                          appCtrl.user?['id'] ??
                                                              '',
                                                      blockBy:
                                                          appCtrl.user?['id'] ??
                                                              '',
                                                    ).marginOnly(
                                                        bottom: Insets.i12);
                                                  } else {
                                                    return MessageCard(
                                                      isForwardList: true,
                                                      // onLongPress: () {
                                                      //   dash.isLongPress = !dash.isLongPress;
                                                      //   dash.update();
                                                      // },
                                                      onTap: () {
                                                        if (dash.isLongPress) {
                                                          if (!dash.selectedChat
                                                              .contains(recentChat
                                                                  .messageList[
                                                                      index]!
                                                                  .id)) {
                                                            dash.selectedChat
                                                                .add(recentChat
                                                                    .messageList[
                                                                        index]!
                                                                    .id);
                                                          } else {
                                                            dash.selectedChat
                                                                .remove(recentChat
                                                                    .messageList[
                                                                        index]!
                                                                    .id);
                                                          }
                                                          dash.update();
                                                        }
                                                      },
                                                      // isLongPress: dash.isLongPress,
                                                      isAvailable: dash
                                                          .selectedChat
                                                          .contains(recentChat
                                                              .messageList[
                                                                  index]!
                                                              .id),
                                                      blockBy:
                                                          appCtrl.user?['id'] ??
                                                              '',
                                                      document: recentChat
                                                          .messageList[index]!,
                                                      data: recentChat
                                                          .messageList[index]!,
                                                      currentUserId:
                                                          appCtrl.user?['id'] ??
                                                              '',
                                                    ).marginOnly(
                                                        bottom: Insets.i12);
                                                  }
                                                } else if (isGroup) {
                                                  return GroupMessageCard(
                                                    isForwardList: true,
                                                    document: recentChat
                                                        .messageList[index],
                                                    // onLongPress: () {
                                                    //   dash.isLongPress = !dash.isLongPress;
                                                    //   dash.update();
                                                    // },
                                                    onTap: () {
                                                      if (dash.isLongPress) {
                                                        if (!dash.selectedChat
                                                            .contains(recentChat
                                                                .messageList[
                                                                    index]!
                                                                .id)) {
                                                          dash.selectedChat.add(
                                                              recentChat
                                                                  .messageList[
                                                                      index]!
                                                                  .id);
                                                        } else {
                                                          dash.selectedChat
                                                              .remove(recentChat
                                                                  .messageList[
                                                                      index]!
                                                                  .id);
                                                        }
                                                        dash.update();
                                                      }
                                                    },
                                                    currentUserId:
                                                        appCtrl.user?['id'] ??
                                                            '',
                                                    // isLongPress: dash.isLongPress,
                                                    isAvailable: dash
                                                        .selectedChat
                                                        .contains(recentChat
                                                            .messageList[index]!
                                                            .id),
                                                  ).marginOnly(
                                                      bottom: Insets.i12);
                                                } else if (isBroadcast) {
                                                  return senderId ==
                                                          appCtrl.user?['id']
                                                      ? BroadCastMessageCard(
                                                          document: recentChat
                                                                  .messageList[
                                                              index]!,
                                                          // isLongPress: dash.isLongPress,
                                                          isAvailable: dash
                                                              .selectedChat
                                                              .contains(recentChat
                                                                  .messageList[
                                                                      index]!
                                                                  .id),
                                                          // onLongPress: () {
                                                          //   dash.isLongPress = !dash.isLongPress;
                                                          //   dash.update();
                                                          // },
                                                          onTap: () {
                                                            if (dash
                                                                .isLongPress) {
                                                              if (!dash
                                                                  .selectedChat
                                                                  .contains(recentChat
                                                                      .messageList[
                                                                          index]!
                                                                      .id)) {
                                                                dash.selectedChat
                                                                    .add(recentChat
                                                                        .messageList[
                                                                            index]!
                                                                        .id);
                                                              } else {
                                                                dash.selectedChat
                                                                    .remove(recentChat
                                                                        .messageList[
                                                                            index]!
                                                                        .id);
                                                              }
                                                              dash.update();
                                                            }
                                                          },
                                                          currentUserId:
                                                              appCtrl.user?[
                                                                      'id'] ??
                                                                  '',
                                                        ).marginOnly(
                                                          bottom: Insets.i12)
                                                      : MessageCard(
                                                          isForwardList: true,
                                                          onLongPress: () {
                                                            dash.isLongPress =
                                                                !dash
                                                                    .isLongPress;
                                                            dash.update();
                                                          },
                                                          onTap: () {
                                                            if (dash
                                                                .isLongPress) {
                                                              if (!dash
                                                                  .selectedChat
                                                                  .contains(recentChat
                                                                      .messageList[
                                                                          index]!
                                                                      .id)) {
                                                                dash.selectedChat
                                                                    .add(recentChat
                                                                        .messageList[
                                                                            index]!
                                                                        .id);
                                                              } else {
                                                                dash.selectedChat
                                                                    .remove(recentChat
                                                                        .messageList[
                                                                            index]!
                                                                        .id);
                                                              }
                                                              dash.update();
                                                            }
                                                          },
                                                          // isLongPress: dash.isLongPress,
                                                          isAvailable: dash
                                                              .selectedChat
                                                              .contains(recentChat
                                                                  .messageList[
                                                                      index]!
                                                                  .id),
                                                          document: recentChat
                                                                  .messageList[
                                                              index]!,
                                                          data: recentChat
                                                                  .messageList[
                                                              index]!,
                                                          currentUserId:
                                                              appCtrl.user?[
                                                                      'id'] ??
                                                                  '',
                                                          blockBy:
                                                              appCtrl.user?[
                                                                      'id'] ??
                                                                  '',
                                                        ).marginOnly(
                                                          bottom: Insets.i12);
                                                }
                                                return Container();
                                              },
                                            )),
                                          ],
                                        );
                                      }),
                                  Divider(
                                          height: 1,
                                          color: appCtrl.appTheme.borderColor)
                                      .paddingSymmetric(vertical: Insets.i20)
                                ]).paddingSymmetric(horizontal: Insets.i20)
                              : const CommonLoader()
                        ])
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      });
    });
  }
}
