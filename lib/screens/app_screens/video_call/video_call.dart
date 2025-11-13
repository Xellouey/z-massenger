import 'dart:math';
import 'package:chatzy/screens/app_screens/video_call/video_call_class.dart';
import '../../../config.dart';
import '../../../controllers/app_pages_controllers/video_call_controller.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/expandable_fab.dart';

class VideoCall extends StatefulWidget {
  const VideoCall({super.key});

  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall>
    with SingleTickerProviderStateMixin {
  final videoCallCtrl = Get.put(VideoCallController());
  late final AnimationController _controller;
  late final Animation<double> expandAnimation;

  @override
  void initState() {
    super.initState();
    var data = Get.arguments;

    // Initialize call data
    videoCallCtrl.channelName = data["channelName"];
    videoCallCtrl.call = data["call"];
    videoCallCtrl.token = data["token"];
    videoCallCtrl.userData = appCtrl.storage.read(session.user);
    videoCallCtrl.isCameraShow = true; // Ensure camera is on by default
    videoCallCtrl.stream = FirebaseFirestore.instance
        .collection(collectionName.calls)
        .doc(appCtrl.user["id"])
        .collection(collectionName.collectionCallHistory)
        .doc(videoCallCtrl.call!.timestamp.toString())
        .snapshots();

    // Initialize animation
    _controller = AnimationController(
      value: 1.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );

    // Initialize Agora AFTER the first frame is built
    // Это гарантирует, что build() завершится до начала async операций
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAgora();
    });
  }

  // Асинхронная инициализация Agora
  Future<void> _initializeAgora() async {
    try {
      await videoCallCtrl.initAgora();
      videoCallCtrl.update();
    } catch (e) {
      debugPrint("Error initializing Agora: $e");
      // Показываем ошибку пользователю
      Get.snackbar(
        appFonts.connectionError.tr,
        appFonts.videoCallInitError.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VideoCallController>(builder: (_) {
      return DirectionalityRtl(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: videoCallCtrl.stream
            as Stream<DocumentSnapshot<Map<String, dynamic>>>,
            builder: (BuildContext context, snapshot) {
              return PopScope(
                canPop: false,
                onPopInvoked: (didPop) async {
                  if (didPop) return;
                  if (snapshot.hasData && snapshot.data!.data() != null) {
                    videoCallCtrl.isAlreadyEndedCall =
                        snapshot.data!.data()!["status"] == 'ended' ||
                            snapshot.data!.data()!["status"] == 'rejected';
                  } else {
                    videoCallCtrl.isAlreadyEndedCall = false;
                  }
                  videoCallCtrl.update();
                  await videoCallCtrl.onCallEnd(context);
                },
                child: Scaffold(
                    backgroundColor: appCtrl.appTheme.white,
                    floatingActionButton: ExpandableFab(
                      distance: 140,
                      children: [
                        ActionButton(
                            onPressed: () {
                              videoCallCtrl.onSwitchCamera();
                            },
                            index: 0,
                            image: eSvgAssets.cameraSwitch),
                        ActionButton(
                          onPressed: () async {
                            videoCallCtrl.isCameraShow =
                            !videoCallCtrl.isCameraShow;
                            if (videoCallCtrl.isCameraShow) {
                              await videoCallCtrl.engine.enableVideo();
                              await videoCallCtrl.engine.startPreview();
                            } else {
                              await videoCallCtrl.engine.disableVideo();
                              await videoCallCtrl.engine.stopPreview();
                            }
                            videoCallCtrl.update();
                          },
                          index: 1,
                          image: videoCallCtrl.isCameraShow
                              ? eSvgAssets.video1
                              : eSvgAssets.video,
                        ),
                        ActionButton(
                          onPressed: () {
                            videoCallCtrl.onToggleMute();
                          },
                          index: 2,
                          image: videoCallCtrl.muted
                              ? eSvgAssets.speaker2
                              : eSvgAssets.mute1,
                        )
                      ],
                    ),
                    body: Stack(
                      children: [
                        videoCallCtrl.isCameraShow
                            ? VideoCallClass().buildNormalVideoUI(videoCallCtrl)
                            : Container(
                          color: appCtrl.appTheme.primary,
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                      videoCallCtrl.call!.isGroup == true
                                          ? videoCallCtrl.call!.groupName!
                                          : videoCallCtrl.call!.receiverName!,
                                      style: AppCss.manropeblack20.textColor(
                                          appCtrl.appTheme.sameWhite)),
                                  const VSpace(Sizes.s10),
                                  if (snapshot.hasData)
                                    snapshot.data!.data() == null
                                        ? Text(
                                      "Вызов...",
                                      style: AppCss.manropeblack14
                                          .textColor(
                                          appCtrl.appTheme.primary),
                                      textAlign: TextAlign.center,
                                    )
                                        : Text(
                                        snapshot.data!.data()!["status"] ==
                                            'pickedUp'
                                            ? appFonts.picked.tr
                                            : snapshot.data!.data()!["status"] ==
                                            'noNetwork'
                                            ? appFonts.connecting.tr
                                            : snapshot.data!.data()!["status"] ==
                                            'ringing' ||
                                            snapshot.data!.data()!["status"] ==
                                                'missedCall'
                                            ? appFonts.calling.tr
                                            : snapshot.data!.data()!["status"] ==
                                            'calling'
                                            ? videoCallCtrl.call!.receiverId ==
                                            appCtrl.user[
                                            "id"]
                                            ? appFonts
                                            .connecting
                                            .tr
                                            : appFonts
                                            .calling.tr
                                            : snapshot.data!.data()!["status"] ==
                                            'pickedUp'
                                            ? appFonts
                                            .onCall.tr
                                            : snapshot.data!.data()!["status"] ==
                                            'ended'
                                            ? appFonts
                                            .callEnded
                                            .tr
                                            : snapshot.data!.data()!["status"] ==
                                            'rejected'
                                            ? appFonts
                                            .callRejected
                                            .tr
                                            : appFonts
                                            .plsWait
                                            .tr,
                                        style: AppCss.manropeblack14
                                            .textColor(appCtrl.appTheme.primary))
                                ]).marginOnly(
                                left: Insets.i45,
                                top: MediaQuery.of(context).size.height / 2,
                                right: Insets.i45),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Image.asset(
                                    eImageAssets.halfEllipse1,
                                    width: MediaQuery.of(context).size.width,
                                    height: 210,
                                    fit: BoxFit.contain,
                                  ),
                                  Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          height: Insets.i64,
                                          width: Insets.i64,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: Insets.i14),
                                          decoration: const BoxDecoration(
                                              color: Color(0XFFEE595C),
                                              shape: BoxShape.circle),
                                          child: SvgPicture.asset(
                                              eSvgAssets.callEnd),
                                        ).inkWell(onTap: () async {
                                          if (snapshot.hasData &&
                                              snapshot.data!.data() != null) {
                                            videoCallCtrl
                                                .isAlreadyEndedCall = snapshot
                                                .data!
                                                .data()!["status"] ==
                                                'ended' ||
                                                snapshot.data!
                                                    .data()!["status"] ==
                                                    'rejected';
                                          } else {
                                            videoCallCtrl.isAlreadyEndedCall =
                                            false;
                                          }
                                          videoCallCtrl.update();
                                          await videoCallCtrl
                                              .onCallEnd(context);
                                        }),
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              eSvgAssets.arrowUp,
                                              height: 22,
                                            ),
                                            RotationTransition(
                                                turns:
                                                const AlwaysStoppedAnimation(
                                                    180 / 360),
                                                child: Image.asset(
                                                  eGifAssets.arrowUp,
                                                  height: 31,
                                                )),
                                          ],
                                        ).marginSymmetric(vertical: Insets.i20)
                                      ])
                                ],
                              ).paddingSymmetric(horizontal: Insets.i35),
                            ),
                          ],
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SvgPicture.asset(eSvgAssets.back).inkWell(
                                  onTap: () async {
                                    await videoCallCtrl.onCallEnd(context);
                                    if (snapshot.hasData &&
                                        snapshot.data!.data() != null) {
                                      videoCallCtrl.isAlreadyEndedCall =
                                          snapshot.data!.data()!["status"] ==
                                              'ended' ||
                                              snapshot.data!.data()!["status"] ==
                                                  'rejected';
                                    } else {
                                      videoCallCtrl.isAlreadyEndedCall = false;
                                    }
                                    videoCallCtrl.update();
                                  }),
                              if (snapshot.hasData &&
                                  snapshot.data!.data() != null)
                                if (videoCallCtrl.localUserJoined)
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        eImageAssets.timeBg,
                                        height: Sizes.s65,
                                        width: Sizes.s100,
                                        fit: BoxFit.fill,
                                      ),
                                      Text(
                                        "${videoCallCtrl.getFormattedTime()}",
                                        style: AppCss.manropeblack14.textColor(
                                            appCtrl.appTheme.sameWhite),
                                      )
                                    ],
                                  )
                            ]).paddingOnly(
                            top: Insets.i55,
                            right: Insets.i20,
                            left: Insets.i20)
                      ],
                    )),
              );
            }),
      );
    });
  }
}
