import 'dart:developer';
import 'package:flutter/cupertino.dart';

import '../../../config.dart';
import '../../../controllers/common_controllers/contact_controller.dart';
import '../../../controllers/common_controllers/contact_controller.dart' as cn;
import '../../../controllers/recent_chat_controller.dart';
import '../../../models/status_model.dart';
import '../../../widgets/common_loader.dart';
import 'layouts/list_tile_layout.dart';

class FetchContact extends StatefulWidget {
  final SharedPreferences? prefs;
  final PhotoUrl? message;

  const FetchContact({super.key, this.prefs, this.message});

  @override
  State<FetchContact> createState() => _FetchContactState();
}

class _FetchContactState extends State<FetchContact> {
  final scrollController = ScrollController();
  bool isLoading = true, isSelected = false, isSearch = false;
  TextEditingController searchText = TextEditingController();
  final invitePeopleCtrl = Get.put(InvitePeopleController());

  @override
  void initState() {
    var data = Get.arguments;
    isSelected = data ?? false;
    setState(() {});
    super.initState();
  }

  String? sharedSecret;
  String? privateKey;

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DirectionalityRtl(child:
    Consumer<ContactProvider>(builder: (context, contactProvider, child) {
      return Consumer<RecentChatController>(
          builder: (context, recentChat, child) {
            return PopScope(
              canPop: false,
              onPopInvoked: (didPop) {
                if (didPop) return;
                contactProvider.onBack();
                Get.back();
              },
              child: Scaffold(
                  backgroundColor: appCtrl.appTheme.white,
                  appBar: AppBar(
                      automaticallyImplyLeading: false,
                      toolbarHeight: Sizes.s80,
                      elevation: 0,
                      titleSpacing: 5,
                      backgroundColor: appCtrl.appTheme.white,
                      title: isSearch
                          ? TextFieldCommon(
                        //  controller: callListCtrl.searchText,
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
                          contactProvider.searchUser(val);
                          searchText.text.isNotEmpty
                              ? Icon(CupertinoIcons.multiply,
                              color: appCtrl.appTheme.white,
                              size: Sizes.s15)
                              .decorated(
                              color: appCtrl.appTheme.darkText
                                  .withOpacity(.3),
                              shape: BoxShape.circle)
                              .marginAll(Insets.i12)
                              .inkWell(onTap: () {
                            isSearch = false;
                            searchText.text = "";
                            setState(() {});
                          })
                              : SvgPicture.asset(eSvgAssets.search,
                              height: Sizes.s15)
                              .marginAll(Insets.i12)
                              .inkWell(onTap: () {
                            isSearch = false;
                            searchText.text = "";
                            setState(() {});
                          });
                        },
                      )
                          : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appFonts.selectContact.tr,
                                style: AppCss.manropeBold16
                                    .textColor(appCtrl.appTheme.darkText)),
                            const VSpace(Sizes.s5),
                            Text(
                                "${contactProvider.allContacts.length} ${appFonts.contact.tr}",
                                style: AppCss.manropeMedium12
                                    .textColor(appCtrl.appTheme.greyText))
                          ]),
                      actions: [
                        if (!isSearch)
                          ActionIconsCommon(
                              icon: eSvgAssets.refresh,
                              color: appCtrl.appTheme.white,
                              onTap: () async {
                                contactProvider
                                    .fetchContacts(appCtrl.user["phone"]);
                                flutterAlertMessage(msg: "Loading..");
                              },
                              hPadding: Insets.i15,
                              vPadding: Insets.i20),
                        if (!isSearch)
                          ActionIconsCommon(
                              icon: eSvgAssets.search,
                              color: appCtrl.appTheme.white,
                              onTap: () async {
                                isSearch = !isSearch;
                                setState(() {});
                              },
                              vPadding: Insets.i20)
                              .marginOnly(right: Insets.i20)
                      ],
                      leading: ActionIconsCommon(
                          icon: appCtrl.isRTL || appCtrl.languageVal == "ar"
                              ? eSvgAssets.arrowRight
                              : eSvgAssets.arrowLeft,
                          onTap: () {
                            contactProvider.onBack();
                            Get.back();
                          },
                          hPadding: Insets.i8,
                          color: appCtrl.appTheme.white,
                          vPadding: Insets.i20)),
                  body: contactProvider.isLoading == true && contactProvider.registeredContacts.isEmpty
                      ? loading()
                      : RefreshIndicator(
                      onRefresh: () async {
                        return contactProvider
                            .fetchContacts(appCtrl.user["phone"]);
                        /* return contactProvider.fetchContacts(context,
                              appCtrl.user["phone"], widget.prefs!, true);*/
                      },
                      child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 15, top: 0),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            Divider(
                                height: 1,
                                thickness: 2,
                                color: appCtrl.appTheme.borderColor)
                                .padding(
                                bottom: Insets.i20,
                                top: Insets.i10,
                                horizontal: Insets.i20),
                            ...appArray.selectContactList.asMap().entries.map(
                                    (e) => e.value['title'] == appFonts.newGroup.tr
                                    ? !appCtrl.usageControlsVal!
                                    .allowCreatingGroup!
                                    ? Container()
                                    : ListTileLayout(
                                    data: e.value,
                                    onTap: () {
                                      if (e.key == 0) {
                                        Get.to(
                                                () =>
                                                GroupMessageScreen(),
                                            arguments: true);
                                      } else {
                                        Get.toNamed(routeName
                                            .newContact)!
                                            .then((value) {
                                          flutterAlertMessage(
                                              msg:
                                              "Contact Sync..");
                                          return contactProvider
                                              .fetchContacts(appCtrl
                                              .user["phone"]);
                                        });
                                      }
                                    })
                                    .paddingSymmetric(
                                    horizontal: Insets.i20)
                                    : ListTileLayout(
                                    data: e.value,
                                    onTap: () {
                                      if (e.key == 0) {
                                        Get.to(
                                                () => GroupMessageScreen(),
                                            arguments: true);
                                      } else {
                                        Get.toNamed(
                                            routeName.newContact)!
                                            .then((value) {
                                          return contactProvider
                                              .fetchContacts(appCtrl
                                              .user["phone"]);
                                        });
                                      }
                                    })
                                    .paddingSymmetric(
                                    horizontal: Insets.i20)),
                            contactProvider.registeredContacts.isEmpty
                                ? const SizedBox()
                                : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Insets.i20),
                                child: Text(appFonts.registerPeople.tr,
                                    style: AppCss.manropeBold14
                                        .textColor(
                                        appCtrl.appTheme.darkText)))
                                .paddingOnly(top: Insets.i10),
                            ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(00),
                                itemCount:
                                contactProvider.registeredContacts.length,
                                itemBuilder: (context, idx) {
                                  cn.RegisterContactDetail user =
                                  contactProvider.registeredContacts[idx];
                                  String phone = user.phone!;
                                  return phone != appCtrl.user["phone"]
                                      ? ListTile(
                                      leading: CachedNetworkImage(
                                          imageUrl: user.image!,
                                          imageBuilder: (context, imageProvider) =>
                                              CircleAvatar(
                                                  backgroundColor: const Color(
                                                      0xffE6E6E6),
                                                  radius: AppRadius.r25,
                                                  backgroundImage:
                                                  imageProvider),
                                          placeholder: (context, url) =>
                                              CircleAvatar(
                                                  backgroundColor: appCtrl
                                                      .appTheme.primary,
                                                  radius: AppRadius.r25,
                                                  child: Text(
                                                      user.name!.isNotEmpty
                                                          ? user.name!.length >
                                                          2
                                                          ? user.name!
                                                          .replaceAll(
                                                          " ", "")
                                                          .substring(
                                                          0, 2)
                                                          .toUpperCase()
                                                          : user
                                                          .name![0]
                                                          : "C",
                                                      style: AppCss
                                                          .manropeMedium14
                                                          .textColor(appCtrl
                                                          .appTheme
                                                          .sameWhite))),
                                          errorWidget: (context, url, error) => CircleAvatar(
                                              backgroundColor: appCtrl.appTheme.primary,
                                              radius: AppRadius.r25,
                                              child: Text(
                                                  user.name!.isNotEmpty
                                                      ? user.name!.length > 2
                                                      ? user.name!.replaceAll(" ", "").substring(0, 2).toUpperCase()
                                                      : user.name![0]
                                                      : "C",
                                                  style: AppCss.manropeMedium14.textColor(appCtrl.appTheme.sameWhite)))),
                                      title: Text(user.name!.capitalizeFirst!, style: AppCss.manropeBold14.textColor(appCtrl.appTheme.darkText)),
                                      subtitle: Text(user.statusDesc!, style: AppCss.manropeMedium14.textColor(appCtrl.appTheme.greyText)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 0.0),
                                      onTap: () async {
                                        if (isSelected == true) {
                                          Get.back(result: {
                                            "name": user.name,
                                            "number": user.phone!,
                                            "photo": user.image
                                          });
                                          setState(() {});
                                        } else {
                                          final RecentChatController
                                          recentChatController =
                                          Provider.of<
                                              RecentChatController>(
                                              Get.context!,
                                              listen: false);

                                          bool isEmpty =
                                              recentChatController.userData
                                                  .where((element) {
                                                return element["receiverId"] ==
                                                    appCtrl
                                                        .user["id"] &&
                                                    element["senderId"] ==
                                                        user.id ||
                                                    element["senderId"] ==
                                                        appCtrl
                                                            .user["id"] &&
                                                        element["receiverId"] ==
                                                            user.id;
                                              }).isEmpty;
                                          log("isEmpty : $isEmpty");
                                          if (!isEmpty) {
                                            int index = recentChatController
                                                .userData
                                                .indexWhere((element) =>
                                            element["receiverId"] ==
                                                appCtrl.user[
                                                "id"] &&
                                                element["senderId"] ==
                                                    user.id ||
                                                element["senderId"] ==
                                                    appCtrl.user[
                                                    "id"] &&
                                                    element["receiverId"] ==
                                                        user.id);
                                            UserContactModel userContact =
                                            UserContactModel(
                                                username: user.name,
                                                uid: user.id,
                                                phoneNumber: user.phone,
                                                image: user.image,
                                                isRegister: true);
                                            var data = {
                                              "chatId": recentChatController
                                                  .userData[index]
                                              ["chatId"],
                                              "data": userContact
                                            };

                                            Get.back();
                                            Get.toNamed(
                                                routeName.chatLayout,
                                                arguments: data);
                                          } else {
                                            UserContactModel userContact =
                                            UserContactModel(
                                                username: user.name,
                                                uid: user.id,
                                                phoneNumber: user.phone,
                                                image: user.image,
                                                isRegister: true);
                                            var data = {
                                              "chatId": "0",
                                              "data": userContact,
                                            };
                                            log("datadata :$data");
                                            Get.back();
                                            Get.toNamed(
                                                routeName.chatLayout,
                                                arguments: data);
                                          }
                                        }
                                      })
                                      : Container();
                                }),
                            // Invite friends button
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: Insets.i20, vertical: Insets.i20),
                              decoration: BoxDecoration(
                                color: appCtrl.appTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppRadius.r12),
                                border: Border.all(
                                  color: appCtrl.appTheme.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: Insets.i20, vertical: Insets.i8),
                                leading: Container(
                                  padding: const EdgeInsets.all(Insets.i10),
                                  decoration: BoxDecoration(
                                    color: appCtrl.appTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.share,
                                    color: appCtrl.appTheme.sameWhite,
                                    size: Sizes.s20,
                                  ),
                                ),
                                title: Text(
                                  appFonts.invitePeople.tr,
                                  style: AppCss.manropeSemiBold16
                                      .textColor(appCtrl.appTheme.darkText),
                                ),
                                subtitle: Text(
                                  "Поделитесь Z Messenger с друзьями",
                                  style: AppCss.manropeMedium12
                                      .textColor(appCtrl.appTheme.greyText),
                                ),
                                trailing: Icon(
                                  appCtrl.isRTL || appCtrl.languageVal == "ar"
                                      ? CupertinoIcons.chevron_left
                                      : CupertinoIcons.chevron_right,
                                  color: appCtrl.appTheme.greyText,
                                  size: Sizes.s20,
                                ),
                                onTap: () {
                                  invitePeopleCtrl.onInvitePeople();
                                },
                              ),
                            )
                          ]))),
            );
          });
    }));
  }

  loading() {
    return Stack(children: [
      Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(appCtrl.appTheme.primary),
          ))
    ]);
  }
}
