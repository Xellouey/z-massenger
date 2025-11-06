import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../../../../../config.dart';
import '../../../chat_message/layouts/full_screen_video_player.dart';
import '../../../chat_message/layouts/sender/reply_sender_layout.dart';

class GroupVideoDoc extends StatefulWidget {
  final MessageModel? document;
final VoidCallback? onLongPress,onTap;
final bool isReceiver;
final String? currentUserId;
  const GroupVideoDoc({super.key, this.document,this.onLongPress,this.isReceiver = false, this.currentUserId,this.onTap});

  @override
  State<GroupVideoDoc> createState() => GroupVideoDocState();
}

class GroupVideoDocState extends State<GroupVideoDoc> {
  VideoPlayerController? videoController;
   Future<void>? initializeVideoPlayerFuture;
  bool startedPlaying = false;

  @override
  void initState() {
    // TODO: implement initState
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
      setState(() {});
    }

    super.initState();
  }
  @override
  void dispose() {
    videoController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GroupChatMessageController>(builder: (chatCtrl) {
      return FutureBuilder(
        future: initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the VideoPlayerController has finished initialization, use
            // the data it provides to limit the aspect ratio of the video.
            return Stack(
              alignment: appCtrl.languageVal == "ar" || appCtrl.isRTL ? Alignment.bottomRight : Alignment.bottomLeft,
              children: [
                Column(
                  children: [
                    if(widget.document!.sender == appCtrl.user['id'])
                      if (widget.document!.replyTo != null &&
                          widget.document!.replyTo != "")
                        ReplySenderLayout(document: widget.document,isGroup: true,).marginSymmetric(horizontal: Sizes.s8),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: Insets.i8),
                      padding: const EdgeInsets.all(Insets.i8),
                      decoration: ShapeDecoration(
                          color: appCtrl.appTheme.primary,
                          shape:  SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius.only(
                                  topLeft:  SmoothRadius(
                                      cornerRadius:  widget.document!.replyTo != null &&
                                          widget.document!.replyTo != ""
                                          ? 0
                                          : 20, cornerSmoothing: 1),
                                  topRight:  SmoothRadius(
                                      cornerRadius:  widget.document!.replyTo != null &&
                                          widget.document!.replyTo != ""
                                          ? 0
                                          : 20, cornerSmoothing: 1),
                                  bottomLeft: const SmoothRadius(
                                      cornerRadius:  20,
                                      cornerSmoothing: 1),
                                  bottomRight: const SmoothRadius(
                                      cornerRadius: 20, cornerSmoothing: 1)))),
                      child: InkWell(
                        onLongPress: widget.onLongPress,
                        onTap: widget.onTap,
                        child: Stack(
                          alignment: appCtrl.isRTL || appCtrl.languageVal == "ar" ? Alignment.bottomRight : Alignment.bottomLeft,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (widget.isReceiver)
                                      if (widget.document!.sender != widget.currentUserId)
                                        Column(children: [
                                          Text(widget.document!.senderName!,
                                              style: AppCss.manropeMedium12
                                                  .textColor(appCtrl.appTheme.primary)).paddingAll(Insets.i5).decorated(color: appCtrl.appTheme.white,borderRadius: BorderRadius.circular(AppRadius.r20)),
                                         const VSpace(Sizes.s5),

                                        ]),
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
                                          aspectRatio:
                                          videoController!.value.aspectRatio,
                                          // Use the VideoPlayer widget to display the video.
                                          child: ClipRRect(
                                            borderRadius: SmoothBorderRadius(
                                                cornerRadius: 15, cornerSmoothing: 1),
                                            child: VideoPlayer(videoController!),
                                          )).width(Sizes.s250),
                                    ), VSpace(Sizes.s5),
                                    IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (widget.document!.isFavourite != null)
                                            if (widget.document!.isFavourite == true)
                                              if(appCtrl.user["id"] == widget.document!.favouriteId.toString())
                                              Icon(Icons.star,color: appCtrl.appTheme.sameWhite,size: Sizes.s10),
                                            if (!widget.isReceiver)
                                              Icon(Icons.done_all_outlined,
                                                  size: Sizes.s15,
                                                  color: widget.document!.isSeen == true
                                                      ? appCtrl.appTheme.sameWhite
                                                      : appCtrl.appTheme.tick),
                                            const HSpace(Sizes.s5),
                                            const HSpace(Sizes.s3),
                                            Text(
                                              DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(
                                                  int.parse(widget.document!.timestamp.toString()))),
                                              style:
                                              AppCss.manropeMedium12.textColor(appCtrl.appTheme.sameWhite),
                                            )
                                          ]
                                        ).paddingSymmetric(horizontal: Insets.i5)
                                    )
                                  ],
                                ),
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

                              ],
                            )

                          ]
                        ).inkWell(onTap: widget.onTap),
                      ),
                    ).paddingOnly(bottom: widget.document!.emoji != null ? Insets.i8 : 0),
                  ],
                ),
                if (widget.document!.emoji != null)
                  EmojiLayout(emoji: widget.document!.emoji)
              ],
            );
          } else {
            // If the VideoPlayerController is still initializing, show a
            // loading spinner.
            return  Container();
          }
        },
      );
    });
  }
}
