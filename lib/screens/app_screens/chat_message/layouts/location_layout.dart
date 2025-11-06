import 'package:chatzy/screens/app_screens/chat_message/layouts/sender/reply_sender_layout.dart';
import 'package:intl/intl.dart';
import '../../../../config.dart';


class LocationLayout extends StatelessWidget {
  final GestureTapCallback? onTap,emojiTap;
  final VoidCallback? onLongPress;
  final MessageModel? document;
  final bool isReceiver, isBroadcast;

  const LocationLayout(
      {super.key,
      this.onLongPress,
      this.emojiTap,
      this.onTap,
      this.document,
      this.isReceiver = false,
      this.isBroadcast = false})
     ;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: IntrinsicWidth(
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if(document!.sender == appCtrl.user['id'])
                if (document!.replyTo != null &&
                    document!.replyTo != "")
                  ReplySenderLayout(document: document).marginSymmetric(horizontal: Sizes.s8),
                Row(
                  children: [
                    if (document!.isForward != null)
                      if (document!.isForward == true)
                        if (appCtrl.user["id"].toString() ==
                            document!.sender.toString())
                          SvgPicture.asset(eSvgAssets.forward,height: Sizes.s15).paddingSymmetric(horizontal: 10),
                    Container(
                        margin: const EdgeInsets.symmetric(horizontal: Insets.i8),
                        decoration: ShapeDecoration(
                            color: appCtrl.appTheme.primary,
                            shape: SmoothRectangleBorder(
                                borderRadius: SmoothBorderRadius.only(
                                        topLeft:  SmoothRadius(
                                        cornerRadius:  document!.replyTo != null &&
                                            document!.replyTo != ""
                                            ? 0
                                            : 20, cornerSmoothing: 1),
                                    topRight:  SmoothRadius(
                                        cornerRadius:  document!.replyTo != null &&
                                            document!.replyTo != ""
                                            ? 0
                                            : 20, cornerSmoothing: 1),
                                    bottomLeft: SmoothRadius(
                                        cornerRadius: isReceiver ? 0 : 20,
                                        cornerSmoothing: 1),
                                    bottomRight: const SmoothRadius(
                                        cornerRadius: 20, cornerSmoothing: 1)))),
                        child:
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          ClipRRect(
                              borderRadius: SmoothBorderRadius(
                                  cornerRadius: 15, cornerSmoothing: 1),
                              child: Image.asset(eImageAssets.map, height: Sizes.s150)),
                              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                if (document!.isFavourite != null)
                                  if (document!.isFavourite == true)
                                    if(appCtrl.user["id"].toString() == document!.favouriteId.toString())
                                    Icon(Icons.star,
                                        color: appCtrl.appTheme.sameWhite, size: Sizes.s10),
                                const HSpace(Sizes.s3),
                                if (!isBroadcast && !isReceiver)
                                  Icon(Icons.done_all_outlined,
                                      size: Sizes.s15,
                                      color: document!.isSeen== true
                                          ? appCtrl.appTheme.sameWhite
                                          : appCtrl.appTheme.tick),
                                const HSpace(Sizes.s5),
                                Text(
                                    DateFormat('HH:mm').format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            int.parse(document!.timestamp!))),
                                    style:
                                    AppCss.manropeBold12.textColor(appCtrl.appTheme.sameWhite))
                              ]).paddingAll(Insets.i6)
                        ]).paddingAll(Insets.i5)),
                  ],
                ),
              
              ]).paddingOnly(bottom: Insets.i10),
            )),
        if (document!.emojiList != null && document!.emojiList!.isNotEmpty)
          Row(

            children: [...document!.emojiList!.asMap().entries.map((e) => Align(
                widthFactor: 0.5,child: EmojiLayout(emoji: e.value['emoji'],onTap: emojiTap,)),)],
          ).paddingSymmetric( horizontal: Insets.i12,)
      ],
    );
  }
}
