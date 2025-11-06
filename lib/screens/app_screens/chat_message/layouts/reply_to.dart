import '../../../../config.dart';

class ReplyTo extends StatefulWidget {
  final GestureTapCallback? onTap;
  final MessageModel? messageModel;
  final Duration? audioDuration, videoDuration;

  const ReplyTo(
      {super.key,
      this.onTap,
      this.messageModel,
      this.audioDuration,
      this.videoDuration});

  @override
  State<ReplyTo> createState() => _ReplyToState();
}

class _ReplyToState extends State<ReplyTo> {
  String? duration;

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
                height: MediaQuery.of(context).size.height / 20,
                width: Sizes.s3,
                color: appCtrl.appTheme.primary),
            const HSpace(Sizes.s10),
            Expanded(
                child: widget.messageModel!.type == MessageType.audio.name ||
                        widget.messageModel!.type == MessageType.video.name
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              widget.messageModel!.type ==
                                      MessageType.audio.name
                                  ? appFonts.audio.tr
                                  : appFonts.video.tr,
                              style: AppCss.manropeMedium16
                                  .textColor(appCtrl.appTheme.darkText)),
                          Text(
                            widget.messageModel!.type == MessageType.audio.name
                                ? getTimeString(widget.audioDuration!.inSeconds)
                                : getTimeString(
                                    widget.videoDuration!.inSeconds),
                            style: AppCss.manropeMedium16
                                .textColor(appCtrl.appTheme.darkText),
                          )
                        ],
                      )
                    : widget.messageModel!.type == MessageType.image.name ||
                            widget.messageModel!.type == MessageType.gif.name
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              widget.messageModel!.type ==
                                      MessageType.image.name
                                  ? Text(appFonts.image.tr)
                                  : Text("gif"),
                              CachedNetworkImage(
                                  imageUrl: decryptMessage(
                                      widget.messageModel!.content)!,
                                  imageBuilder: (context, imageProvider) =>
                                      Container(
                                          height: 40,
                                          width: 40,
                                          alignment: Alignment.center,
                                          decoration: ShapeDecoration(
                                              shape: SmoothRectangleBorder(
                                                  borderRadius:
                                                      SmoothBorderRadius(
                                                          cornerRadius: 5,
                                                          cornerSmoothing: 1)),
                                              image: DecorationImage(
                                                  fit: BoxFit.cover,
                                                  image: imageProvider))),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        height: 40,
                                        width: 40,
                                        alignment: Alignment.center,
                                        decoration: ShapeDecoration(
                                            shape: SmoothRectangleBorder(
                                                borderRadius:
                                                    SmoothBorderRadius(
                                                        cornerRadius: 5,
                                                        cornerSmoothing: 1)),
                                            color: appCtrl.appTheme.tick),
                                      )).marginSymmetric(horizontal: Sizes.s10)
                            ],
                          )
                        : widget.messageModel!.type == MessageType.contact.name
                            ? Text(
                                "${appFonts.contact.tr} : ${decryptMessage(widget.messageModel!.content).split('-BREAK-')[0]}")
                            : widget.messageModel!.type == MessageType.doc.name
                                ? Text(
                                    decryptMessage(widget.messageModel!.content)
                                        .split('-BREAK-')[0])
                                : Text(
                                    '${decryptMessage(widget.messageModel!.content)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
            // if (onCancelReply != null)
            GestureDetector(
                onTap: widget.onTap,
                child: Icon(Icons.close,
                    size: 16, color: appCtrl.appTheme.primary))
          ])
    ])
        .paddingAll(Sizes.s12)
        .decorated(
            color: const Color(0xff7F83841A).withOpacity(0.10),
            borderRadius: BorderRadius.circular(Sizes.s10))
        .padding(bottom: Sizes.s6);
  }
}
