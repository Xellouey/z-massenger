import 'dart:developer';

import 'package:chatzy/screens/app_screens/chat_message/layouts/full_screen_video_player.dart';
import 'package:chatzy/screens/app_screens/chat_message/layouts/sender/reply_sender_layout.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../../../config.dart';

class VideoDoc extends StatefulWidget {
  final MessageModel? document;
  final bool isBroadcast, isReceiver;
  final GestureTapCallback? onTap, emojiTap;
  final VoidCallback? onLongPress;
  final Function(Duration)? duration;

  const VideoDoc(
      {super.key,
      this.document,
      this.isBroadcast = false,
      this.isReceiver = false,
      this.onTap,
      this.emojiTap,
      this.duration,
      this.onLongPress});

  @override
  State<VideoDoc> createState() => _VideoDocState();
}

class _VideoDocState extends State<VideoDoc> {
  VideoPlayerController? videoController;
  Future<void>? initializeVideoPlayerFuture;
  bool startedPlaying = false;

  Duration? _videoDuration;

  @override
  initState() {
    log("VIDEO LINK ${decryptMessage(widget.document!.content).split("-BREAK-")}");
    // TODO: implement initState
    initializeVideo();
    super.initState();
  }

  Future<void> initializeVideo() async {
    if (widget.document!.type == MessageType.video.name) {
      videoController = VideoPlayerController.networkUrl(Uri.parse(
          decryptMessage(widget.document!.content).contains("-BREAK-")
              ? decryptMessage(widget.document!.content).split("-BREAK-")[1]
              : decryptMessage(widget.document!.content)));
      videoController!.addListener(() {
        setState(() {});
      });
      videoController!.setLooping(true);
      initializeVideoPlayerFuture = videoController!.initialize();
      setState(() {
        _videoDuration = videoController!.value.duration;
        widget.duration!(_videoDuration!);
      });
    }
  }

  @override
  void dispose() {
    videoController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the VideoPlayerController has finished initialization, use
          // the data it provides to limit the aspect ratio of the video.
          return Stack(alignment: Alignment.bottomLeft, children: [
            InkWell(
                onLongPress: widget.onLongPress,
                onTap: widget.onTap,
                child: IntrinsicWidth(
                  child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                        if (widget.document!.sender == appCtrl.user['id'])
                          if (widget.document!.replyTo != null &&
                              widget.document!.replyTo != "")
                            ReplySenderLayout(document: widget.document),
                        Row(
                          children: [
                            if (widget.document!.isForward != null)
                              if (widget.document!.isForward == true)
                                if (appCtrl.user["id"].toString() ==
                                    widget.document!.sender.toString())
                                  SvgPicture.asset(eSvgAssets.forward,
                                          height: Sizes.s15)
                                      .paddingSymmetric(horizontal: 10),
                            Stack(alignment: Alignment.center, children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FullScreenVideoPlayer(
                                                    videoController:
                                                        videoController!),
                                          ),
                                        );
                                      },
                                      child: AspectRatio(
                                          aspectRatio: videoController!
                                              .value.aspectRatio,
                                          // Use the VideoPlayer widget to display the video.
                                          child: ClipRRect(
                                            borderRadius: SmoothBorderRadius(
                                                cornerRadius: 15,
                                                cornerSmoothing: 1),
                                            child:
                                                VideoPlayer(videoController!),
                                          )).width(Sizes.s250),
                                    ),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (widget.document!.isFavourite !=
                                              null)
                                            if (widget.document!.isFavourite ==
                                                true)
                                              if (appCtrl.user["id"]
                                                      .toString() ==
                                                  widget.document!.favouriteId
                                                      .toString())
                                                Icon(Icons.star,
                                                    color: appCtrl
                                                        .appTheme.sameWhite,
                                                    size: Sizes.s10),
                                          const HSpace(Sizes.s3),
                                          if (!widget.isBroadcast &&
                                              !widget.isReceiver)
                                            Icon(Icons.done_all_outlined,
                                                size: Sizes.s15,
                                                color: widget
                                                            .document!.isSeen ==
                                                        true
                                                    ? appCtrl.appTheme.sameWhite
                                                    : appCtrl.appTheme.tick),
                                          const HSpace(Sizes.s5),
                                          Text(
                                              DateFormat('HH:mm').format(
                                                  DateTime
                                                      .fromMillisecondsSinceEpoch(
                                                          int.parse(widget
                                                              .document!
                                                              .timestamp!))),
                                              style: AppCss.manropeBold12
                                                  .textColor(appCtrl
                                                      .appTheme.sameWhite))
                                        ]).padding(
                                        top: Insets.i5, horizontal: Insets.i5)
                                  ]),
                              IconButton(
                                  icon: Icon(Icons.play_arrow,
                                          color: appCtrl.appTheme.white)
                                      .marginAll(Insets.i3)
                                      .decorated(
                                          color: appCtrl.appTheme.secondary,
                                          shape: BoxShape.circle),
                                  onPressed: () {
                                    if (videoController!.value.isPlaying) {
                                      videoController!.pause();
                                    } else {
                                      // If the video is paused, play it.
                                      videoController!.play();
                                    }
                                    setState(() {});
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                FullScreenVideoPlayer(
                                                    videoController:
                                                        videoController!)));
                                  })
                            ])
                                .paddingAll(Insets.i5)
                                .decorated(
                                    color: appCtrl.appTheme.primary,
                                    borderRadius: SmoothBorderRadius.only(
                                        topLeft: SmoothRadius(
                                            cornerRadius: widget.document!.replyTo !=
                                                        null &&
                                                    widget.document!.replyTo !=
                                                        ""
                                                ? 0
                                                : 20,
                                            cornerSmoothing: 1),
                                        topRight: SmoothRadius(
                                            cornerRadius:
                                                widget.document!.replyTo != null &&
                                                        widget.document!.replyTo !=
                                                            ""
                                                    ? 0
                                                    : 20,
                                            cornerSmoothing: 1),
                                        bottomLeft: const SmoothRadius(
                                            cornerRadius: 20,
                                            cornerSmoothing: 1),
                                        bottomRight: const SmoothRadius(
                                            cornerRadius: 20,
                                            cornerSmoothing: 1)))
                                .paddingOnly(bottom: Insets.i10),
                          ],
                        )
                      ])
                      .paddingSymmetric(
                          horizontal: Insets.i8, vertical: Insets.i5)
                      .inkWell(onTap: widget.onTap),
                )),
            if (widget.document!.emojiList != null &&
                widget.document!.emojiList!.isNotEmpty)
              Row(
                children: [
                  ...widget.document!.emojiList!.asMap().entries.map(
                        (e) => Align(
                            widthFactor: 0.5,
                            child: EmojiLayout(
                              emoji: e.value['emoji'],
                              onTap: widget.emojiTap,
                            )),
                      )
                ],
              ).paddingSymmetric(
                horizontal: Insets.i12,
              )
          ]);
        } else {
          // If the VideoPlayerController is still initializing, show a
          // loading spinner.
          return const Row(
            children: [
              HSpace(Sizes.s20),
              CircularProgressIndicator(),
              HSpace(Sizes.s20),
            ],
          );
        }
      },
    );
  }
}
