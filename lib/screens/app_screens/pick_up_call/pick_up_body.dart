import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:chatzy/controllers/recent_chat_controller.dart';
import 'package:chatzy/models/call_model.dart';
import 'package:chatzy/widgets/action_icon_common.dart';
import '../../../config.dart';
import '../../../controllers/app_pages_controllers/video_call_controller.dart';
import '../../../controllers/common_controllers/all_permission_handler.dart';
import '../../../controllers/common_controllers/notification_controller.dart';
import '../../../widgets/expandable_fab.dart';

class PickupBody extends StatelessWidget {
  final Call? call;
  final CameraController? cameraController;
  final String? imageUrl;
  final VoidCallback? onCallEnded;

  const PickupBody({
    super.key,
    this.call,
    this.imageUrl,
    this.cameraController,
    this.onCallEnded,
  });

  void _navigateToChat(BuildContext context) {
    final recentChatCtrl =
    Provider.of<RecentChatController>(context, listen: false);
    final userData = recentChatCtrl.userData;

    // Определяем, кто "другой" пользователь в звонке
    // Если я звонящий (callerId), то другой - получатель (receiverId)
    // Если я получатель (receiverId), то другой - звонящий (callerId)
    final bool isICaller = call!.callerId == appCtrl.user["id"];
    final String otherUserId = isICaller ? call!.receiverId! : call!.callerId!;
    final String otherUserName = isICaller ? call!.receiverName! : call!.callerName!;
    final String otherUserPic = isICaller ? call!.receiverPic! : call!.callerPic!;

    final isExistingChat = userData.any((element) =>
    (element["receiverId"] == appCtrl.user["id"] &&
        element["senderId"] == otherUserId) ||
        (element["senderId"] == appCtrl.user["id"] &&
            element["receiverId"] == otherUserId));

    UserContactModel userContact = UserContactModel(
      username: otherUserName,
      uid: otherUserId,
      phoneNumber: '',
      image: otherUserPic,
      isRegister: true,
    );

    if (isExistingChat) {
      final index = userData.indexWhere((element) =>
      (element["receiverId"] == appCtrl.user["id"] &&
          element["senderId"] == otherUserId) ||
          (element["senderId"] == appCtrl.user["id"] &&
              element["receiverId"] == otherUserId));
      userContact = UserContactModel(
        username: otherUserName,
        uid: otherUserId,
        phoneNumber: userData[index].data()['phone'] ?? '',
        image: userData[index].data()['image'] ?? otherUserPic,
        isRegister: true,
      );
      Get.toNamed(routeName.chatLayout, arguments: {
        'chatId': userData[index]['chatId'],
        'data': userContact,
        'message': appFonts.callYouLater.tr,
        'isCallEnd': true,
      });
    } else {
      Get.toNamed(routeName.chatLayout, arguments: {
        'chatId': '0',
        'data': userContact,
        'message': appFonts.callYouLater.tr,
        'isCallEnd': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ExpandableFab(
        distance: 110,
        children: [
          Container(
            height: Insets.i64,
            width: Insets.i64,
            margin: const EdgeInsets.symmetric(horizontal: Insets.i15),
            padding: const EdgeInsets.symmetric(horizontal: Insets.i14),
            decoration: const BoxDecoration(
                color: Color(0xFFEE595C), shape: BoxShape.circle),
            child: SvgPicture.asset(eSvgAssets.callEnd),
          ).inkWell(onTap: () async {
            // Stop vibration when call is declined
            await Vibration.cancel();
            final videoCtrl = Get.isRegistered<VideoCallController>()
                ? Get.find<VideoCallController>()
                : Get.put(VideoCallController());
            await videoCtrl.endCall(call: call!);
            await cameraController?.dispose();
            onCallEnded?.call();
            _navigateToChat(context);
          }),
          Container(
            height: Insets.i64,
            width: Insets.i64,
            padding: const EdgeInsets.symmetric(horizontal: Insets.i14),
            decoration: BoxDecoration(
                color: appCtrl.appTheme.online, shape: BoxShape.circle),
            child: SvgPicture.asset(
              eSvgAssets.call,
              colorFilter:
              ColorFilter.mode(appCtrl.appTheme.sameWhite, BlendMode.srcIn),
            ),
          ).inkWell(onTap: () async {
            // Stop vibration when call is accepted
            await Vibration.cancel();

            // Stop ringtone by cancelling notification
            try {
              final noti = Get.find<CustomNotificationController>();
              await noti.cancelAllNotifications();
            } catch (e) {
              log('❌ Error cancelling notifications: $e');
            }

            // Показываем индикатор загрузки
            Get.dialog(
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              barrierDismissible: false,
            );

            try {
              final permissionCtrl =
              Get.isRegistered<PermissionHandlerController>()
                  ? Get.find<PermissionHandlerController>()
                  : Get.put(PermissionHandlerController());

              log('📞 Requesting permissions for call...');
              bool hasPermissions =
              await permissionCtrl.getCameraMicrophonePermissions();

              if (!hasPermissions) {
                log('❌ Permissions not granted for call');
                Get.back(); // Закрываем индикатор
                Get.snackbar(
                  'Разрешения необходимы',
                  'Пожалуйста, разрешите доступ к камере и микрофону.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: appCtrl.appTheme.redColor,
                  colorText: appCtrl.appTheme.white,
                  duration: const Duration(seconds: 3),
                );
                return;
              }

              log('✅ Permissions granted, accepting call...');

              await cameraController?.dispose();

              var data = {
                'channelName': call!.channelId,
                'call': call,
                'token': call!.agoraToken ?? '',
              };

              // Закрываем индикатор загрузки
              Get.back();

              log('✅ Opening ${call!.isVideoCall == true ? "video" : "audio"} call screen');

              Get.toNamed(
                call!.isVideoCall == true
                    ? routeName.videoCall
                    : routeName.audioCall,
                arguments: data,
              );
            } catch (e, stackTrace) {
              log('❌ Error accepting call: $e');
              log('Stack trace: $stackTrace');

              // Закрываем индикатор загрузки
              if (Get.isDialogOpen == true) {
                Get.back();
              }

              Get.snackbar(
                'Ошибка',
                'Не удалось принять звонок. Попробуйте еще раз.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: appCtrl.appTheme.redColor,
                colorText: appCtrl.appTheme.white,
                duration: const Duration(seconds: 3),
              );
            }
          }),
        ],
      ),
      body: Stack(
        children: [
          /*      call!.isVideoCall == true
              ?*/
          cameraController != null && cameraController!.value.isInitialized
              ? CameraPreview(cameraController!)
              .height(MediaQuery.of(context).size.height)
              : Container(
            color: appCtrl.appTheme.white,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
          ),
          call!.isVideoCall == true
              ? Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        call!.isGroup == true
                            ? call!.groupName!
                            : call!.callerId == appCtrl.user["id"]
                            ? call!.receiverName!
                            : call!.callerName!,
                        style: AppCss.manropeblack20
                            .textColor(appCtrl.appTheme.darkText),
                      ),
                      const VSpace(Sizes.s10),
                      Text(
                        'Вызов...',
                        style: AppCss.manropeblack14
                            .textColor(appCtrl.appTheme.primary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ).marginOnly(
                    left: Insets.i45,
                    top: MediaQuery.of(context).size.height / 2,
                    right: Insets.i45,
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Image.asset(eImageAssets.halfEllipse),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SvgPicture.asset(
                                  eSvgAssets.arrowUp,
                                  height: 22,
                                ),
                                RotationTransition(
                                  turns: const AlwaysStoppedAnimation(
                                      180 / 360),
                                  child: Image.asset(
                                    eGifAssets.arrowUp,
                                    height: 31,
                                  ),
                                ),
                              ],
                            ).marginSymmetric(vertical: Insets.i20),
                          ],
                        ),
                      ],
                    ).paddingSymmetric(horizontal: Insets.i50),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(eSvgAssets.back).inkWell(
                    onTap: () async {
                      // Stop vibration when back button is pressed
                      await Vibration.cancel();
                      final videoCtrl =
                      Get.isRegistered<VideoCallController>()
                          ? Get.find<VideoCallController>()
                          : Get.put(VideoCallController());
                      await videoCtrl.endCall(call: call!);
                      await cameraController?.dispose();
                      onCallEnded?.call();
                      _navigateToChat(context);
                    },
                  ),
                ],
              ).paddingOnly(
                  top: Insets.i55, right: Insets.i20, left: Insets.i20),
            ],
          )
              : Stack(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(collectionName.users)
                    .doc(call!.callerId == appCtrl.user['id']
                    ? call!.receiverId
                    : call!.callerId)
                    .snapshots(),
                builder: (context, snapShot) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          DottedBorder(
                            color:
                            appCtrl.appTheme.primary.withOpacity(.16),
                            strokeWidth: 1.4,
                            dashPattern: const [5, 5],
                            borderType: BorderType.Circle,
                            child: SizedBox(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(eImageAssets.customEllipse),
                                  Container(
                                    height: Sizes.s96,
                                    width: Sizes.s96,
                                    padding:
                                    const EdgeInsets.all(Insets.i5),
                                    margin: const EdgeInsets.only(
                                        bottom: Insets.i10,
                                        right: Insets.i5),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color:
                                          appCtrl.appTheme.primary),
                                      image: /*snapShot.hasData &&
                                                    snapShot.data!.data() !=
                                                        null
                                                ? DecorationImage(
                                                    fit: BoxFit.cover,
                                                    image: NetworkImage(snapShot
                                                        .data!
                                                        .data()!['image']))
                                                :*/
                                      DecorationImage(
                                          fit: BoxFit.cover,
                                          image: AssetImage(
                                              eImageAssets
                                                  .anonymous)),
                                    ),
                                  ),
                                ],
                              ).paddingAll(Insets.i30),
                            ),
                          ),
                          const VSpace(Sizes.s40),
                          Text(
                            call!.isGroup == true
                                ? '${call!.groupName!} Audio Call'
                                : call!.callerId == appCtrl.user["id"]
                                ? '${call!.receiverName!} Audio Call'
                                : '${call!.callerName!} Audio Call',
                            style: AppCss.manropeblack20
                                .textColor(appCtrl.appTheme.black),
                          ),
                          const VSpace(Sizes.s10),
                          Text(
                            'Вызов...',
                            style: AppCss.manropeblack14
                                .textColor(appCtrl.appTheme.primary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ).marginOnly(
                          left: Insets.i45,
                          top: MediaQuery.of(context).size.height / 7,
                          right: Insets.i45),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Image.asset(eImageAssets.halfEllipse),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      eSvgAssets.arrowUp,
                                      height: 22,
                                    ),
                                    RotationTransition(
                                      turns: const AlwaysStoppedAnimation(
                                          180 / 360),
                                      child: Image.asset(
                                        eGifAssets.arrowUp,
                                        height: 31,
                                      ),
                                    ),
                                  ],
                                ).marginSymmetric(vertical: Insets.i20),
                              ],
                            ),
                          ],
                        ).paddingSymmetric(horizontal: Insets.i50),
                      ),
                    ],
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ActionIconsCommon(
                    onTap: () async {
                      // Stop vibration when back button is pressed
                      await Vibration.cancel();
                      final videoCtrl =
                      Get.isRegistered<VideoCallController>()
                          ? Get.find<VideoCallController>()
                          : Get.put(VideoCallController());
                      await videoCtrl.endCall(call: call!);
                      await cameraController?.dispose();
                      onCallEnded?.call();
                      _navigateToChat(context);
                    },
                    icon: appCtrl.isRTL || appCtrl.languageVal == 'ar'
                        ? eSvgAssets.arrowRight
                        : eSvgAssets.arrowLeft,
                    vPadding: Insets.i15,
                    color: appCtrl.appTheme.white,
                    hPadding: 15,
                  ),
                ],
              ).paddingOnly(top: Insets.i55),
            ],
          ),
        ],
      ),
    );
  }
}
