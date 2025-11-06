import 'package:chatzy/screens/app_screens/chat_message/layouts/sender/reply_sender_layout.dart';
import 'package:intl/intl.dart';

import '../../../../../config.dart';

class ReceiverContent extends StatelessWidget {
  final MessageModel? document;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onTap, emojiTap;

  const ReceiverContent(
      {super.key, this.document, this.onLongPress, this.onTap, this.emojiTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onLongPress: onLongPress,
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          /*  if (document!.replyTo != null && document!.replyTo != "")
            ReplySenderLayout(document: document), */
          Stack(alignment: Alignment.bottomLeft, children: [
            decryptMessage(document!.content).length > 30
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Insets.i12, vertical: Insets.i14),
                    width: Sizes.s230,
                    decoration: ShapeDecoration(
                        color: Color(0xFF2F4F4F),
                        shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius.only(
                                topLeft: SmoothRadius(
                                    cornerRadius: document!.replyTo != null &&
                                            document!.replyTo != ""
                                        ? 0
                                        : 20,
                                    cornerSmoothing: 1),
                                topRight: SmoothRadius(
                                    cornerRadius: document!.replyTo != null &&
                                            document!.replyTo != ""
                                        ? 0
                                        : 20,
                                    cornerSmoothing: 1),
                                bottomRight: const SmoothRadius(
                                    cornerRadius: 20, cornerSmoothing: 1)))),
                    /* ShapeDecoration(
                      color: appCtrl.appTheme.primary,
                      shape: const SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius.only(
                              topLeft: SmoothRadius(
                                  cornerRadius: 20, cornerSmoothing: 1),
                              topRight: SmoothRadius(
                                  cornerRadius: 20, cornerSmoothing: 1),
                              bottomRight: SmoothRadius(
                                  cornerRadius: 20, cornerSmoothing: 1))),
                    ), */

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(decryptMessage(document!.content),
                            overflow: TextOverflow.clip,
                            style: /* document!.type == MessageType.emoji.name
                                ? AppCss.manropeSemiBold24
                                    .textColor(appCtrl.appTheme.sameWhite)
                                    .letterSpace(.2)
                                    .textHeight(1.2)
                                : */
                                AppCss.manropeSemiBold14
                                    .textColor(appCtrl.appTheme.sameWhite)
                                    .letterSpace(.2)
                                    .textHeight(1.2)),
                        const VSpace(Sizes.s8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (document!.isFavourite != null)
                              if (document!.isFavourite == true)
                                if (appCtrl.user["id"].toString() ==
                                    document!.favouriteId.toString())
                                  Icon(Icons.star,
                                      color: appCtrl.appTheme.greyText,
                                      size: Sizes.s10),
                            if (document!.isBroadcast!) const HSpace(Sizes.s3),
                            if (document!.isBroadcast!)
                              const Icon(Icons.volume_down, size: Sizes.s15),
                            const HSpace(Sizes.s5),
                            Text(
                              DateFormat('HH:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(document!.timestamp!))),
                              style: AppCss.manropeMedium12
                                  .textColor(appCtrl.appTheme.sameWhite),
                            ),
                          ],
                        ).alignment(Alignment.bottomRight)
                      ],
                    )).paddingOnly(bottom: Insets.i10)
                : IntrinsicWidth(
                    child: Column(mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (document!.replyTo != null &&
                            document!.replyTo != "")
                          ReplySenderLayout(document: document),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Insets.i12, vertical: Insets.i10),
                            decoration: ShapeDecoration(
                                color: Color(0xFF2F4F4F),
                                shape: SmoothRectangleBorder(
                                    borderRadius: SmoothBorderRadius.only(
                                        topLeft: SmoothRadius(
                                            cornerRadius:
                                                document!.replyTo != null &&
                                                        document!.replyTo != ""
                                                    ? 0
                                                    : 20,
                                            cornerSmoothing: 1),
                                        topRight: SmoothRadius(
                                            cornerRadius:
                                                document!.replyTo != null &&
                                                        document!.replyTo != ""
                                                    ? 0
                                                    : 20,
                                            cornerSmoothing: 1),
                                        bottomRight: const SmoothRadius(
                                            cornerRadius: 20,
                                            cornerSmoothing:
                                                1))) /* const SmoothRectangleBorder(borderRadius: SmoothBorderRadius.only(topLeft: SmoothRadius(cornerRadius: 18, cornerSmoothing: 1), topRight: SmoothRadius(cornerRadius: 18, cornerSmoothing: 1), bottomRight: SmoothRadius(cornerRadius: 18, cornerSmoothing: 1))) */),
                            child:
                                Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisSize: MainAxisSize.min,children: [
                              Text(decryptMessage(document!.content),
                                  overflow: TextOverflow.clip,
                                 maxLines: 200,
                                  style:/* document!.type ==
                                          MessageType.emoji.name
                                      ? AppCss.manropeSemiBold24
                                          .textColor(appCtrl.appTheme.sameWhite)
                                          .letterSpace(.2)
                                          .textHeight(1.2)
                                      : */AppCss.manropeSemiBold14
                                          .textColor(appCtrl.appTheme.sameWhite)
                                          .letterSpace(.2)
                                          .textHeight(1.2)),
                              const VSpace(Sizes.s8),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (document!.isFavourite != null)
                                      if (document!.isFavourite == true)
                                        if (appCtrl.user["id"].toString() ==
                                            document!.favouriteId.toString())
                                          Icon(Icons.star,
                                              color: appCtrl.appTheme.greyText,
                                              size: Sizes.s10),
                                    if (document!.isBroadcast!)
                                      const HSpace(Sizes.s3),
                                    if (document!.isBroadcast!)
                                      const Icon(Icons.volume_down,
                                          size: Sizes.s15),
                                    const HSpace(Sizes.s5),
                                    Text(
                                        DateFormat('HH:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                                int.parse(
                                                    document!.timestamp!))),
                                        style: AppCss.manropeMedium12.textColor(
                                            appCtrl.appTheme.sameWhite))
                                  ])
                            ])).paddingOnly(bottom: document!.emoji != null ? Insets.i10 : 0),
                      ],
                    ),
                  ),
            if (document!.emojiList != null && document!.emojiList!.isNotEmpty)
              Row(children: [
                ...document!.emojiList!.asMap().entries.map((e) => Align(
                    widthFactor: 0.5,
                    child:
                        EmojiLayout(emoji: e.value['emoji'], onTap: emojiTap)))
              ])
          ])
        ]).marginSymmetric(horizontal: Insets.i12));
  }
}
