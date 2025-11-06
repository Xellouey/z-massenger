import 'package:chatzy/screens/app_screens/chat_message/layouts/sender/reply_sender_layout.dart';
import 'package:intl/intl.dart';

import '../../../../config.dart';
import 'doc_content.dart';

class DocxLayout extends StatelessWidget {
  final MessageModel? document;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onTap,emojiTap;
  final bool isReceiver, isGroup, isBroadcast;
  final String? currentUserId;

  const DocxLayout(
      {super.key,
      this.document,
      this.emojiTap,
      this.onLongPress,
      this.isReceiver = false,
      this.isGroup = false,
      this.isBroadcast = false,
      this.currentUserId,
      this.onTap})
     ;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InkWell(
            onLongPress: onLongPress,
            onTap: onTap,
            child: IntrinsicWidth(
              child: IntrinsicWidth(
                child: Column(
                  children: [
                    if (document!.sender == appCtrl.user['id'])
                      if (document!.replyTo != null &&
                          document!.replyTo != "")
                        ReplySenderLayout(document: document,isGroup: isGroup,),
                    Row(
                      children: [
                        if (document!.isForward != null)
                          if (document!.isForward == true)
                            if (appCtrl.user["id"].toString() ==
                                document!.sender.toString())
                              SvgPicture.asset(eSvgAssets.forward,height: Sizes.s15).paddingSymmetric(horizontal: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [

                            DocContent(
                                    isReceiver: isReceiver,
                                    isBroadcast: isBroadcast,
                                    document: document,
                                    currentUserId: currentUserId,
                                    isGroup: isGroup)
                                .marginSymmetric(horizontal: Insets.i10),
                            Row(crossAxisAlignment: CrossAxisAlignment.end,mainAxisAlignment: MainAxisAlignment.end, children: [
                              if (document!.isFavourite != null)
                                if (document!.isFavourite == true)
                                  if(appCtrl.user["id"].toString() == document!.favouriteId.toString())
                                  Icon(Icons.star,
                                      color: appCtrl.appTheme.sameWhite, size: Sizes.s10),
                              const HSpace(Sizes.s3),
                              if (!isGroup)
                                if (!isReceiver && !isBroadcast)
                                  Icon(Icons.done_all_outlined,
                                      size: Sizes.s15,
                                      color: document!.isSeen == true
                                          ? appCtrl.appTheme.sameWhite
                                          : appCtrl.appTheme.tick),
                              const HSpace(Sizes.s5),
                              IntrinsicHeight(
                                  child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (document!.isFavourite != null)
                                          if (document!.isFavourite == true)
                                            if(appCtrl.user["id"].toString() == document!.favouriteId.toString())
                                            Icon(Icons.star,
                                                color: appCtrl.appTheme.sameWhite, size: Sizes.s10),
                                        const HSpace(Sizes.s3),
                                        Text(
                                            DateFormat('HH:mm').format(
                                                DateTime.fromMillisecondsSinceEpoch(
                                                    int.parse(document!.timestamp!))),
                                            style: AppCss.manropeMedium12
                                                .textColor(appCtrl.appTheme.sameWhite))
                                      ]))
                            ]).marginSymmetric(vertical: Insets.i8, horizontal: Insets.i10)
                          ]
                        ).decorated(
                            color:  appCtrl.appTheme.primary, borderRadius: SmoothBorderRadius.only(
                            topLeft: SmoothRadius(
                                cornerRadius:
                                document!.replyTo != null &&
                                    document!.replyTo != ""
                                    ? 0
                                    : 8,
                                cornerSmoothing: 1),
                            topRight: SmoothRadius(
                                cornerRadius:
                                document!.replyTo != null &&
                                    document!.replyTo != ""
                                    ? 0
                                    : 8,
                                cornerSmoothing: 1),
                            bottomLeft: const SmoothRadius(
                                cornerRadius: 8,
                                cornerSmoothing: 1))),
                      ],
                    ),
                  ],
                ),
              ),
            )).paddingSymmetric(vertical: Insets.i10,horizontal: Insets.i10),
        if (document!.emojiList != null &&
            document!.emojiList!.isNotEmpty)
          Row(children: [
            ...document!.emojiList!.asMap().entries.map((e) => Align(
                widthFactor: 0.5,
                child: EmojiLayout(
                    emoji: e.value['emoji'], onTap: emojiTap)))
          ])
      ],
    );
  }
}
