import 'dart:developer';

import 'package:chatzy/screens/app_screens/chat_message/layouts/sender/reply_sender_layout.dart';
import 'package:intl/intl.dart';
import '../../../../../config.dart';

class Content extends StatelessWidget {
  final MessageModel? document;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onTap, emojiTap;
  final bool isBroadcast;
  final String? userId;

  const Content(
      {super.key,
      this.document,
      this.onLongPress,
      this.emojiTap,
      this.onTap,
      this.isBroadcast = false,
      this.userId});

  @override
  Widget build(BuildContext context) {
    // log("document!.emoji ${document!.emoji!}///${document!.emojiList}");
    // var chatCtrl = Get.put(ChatController());
    return Stack(
      // alignment: Alignment.bottomRight,
      children: [
        InkWell(
            onLongPress: onLongPress,
            onTap: onTap,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              decryptMessage(document!.content).length > 30
                  ? Column(
                      children: [
                        if (document!.sender == appCtrl.user['id'])
                          if (document!.replyTo != null &&
                              document!.replyTo != "")
                            ReplySenderLayout(document: document),
                        Row(
                          children: [
                            if (document!.isForward != null)
                              if (document!.isForward == true)
                                if (appCtrl.user["id"].toString() ==
                                    document!.sender.toString())
                                  SvgPicture.asset(eSvgAssets.forward,
                                          height: Sizes.s15)
                                      .paddingSymmetric(horizontal: 10),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Insets.i12,
                                    vertical: Insets.i14),
                                width: Sizes.s280,
                                decoration: ShapeDecoration(
                                    color: appCtrl.appTheme.primary,
                                    shape: SmoothRectangleBorder(
                                        borderRadius: SmoothBorderRadius.only(
                                            topLeft: SmoothRadius(
                                                cornerRadius: document!.replyTo !=
                                                            null &&
                                                        document!.replyTo != ""
                                                    ? 0
                                                    : 20,
                                                cornerSmoothing: 1),
                                            topRight: SmoothRadius(
                                                cornerRadius:
                                                    document!.replyTo != null &&
                                                            document!.replyTo !=
                                                                ""
                                                        ? 0
                                                        : 20,
                                                cornerSmoothing: 1),
                                            bottomLeft: const SmoothRadius(
                                                cornerRadius: 20,
                                                cornerSmoothing: 1)))),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text(decryptMessage(document!.content),
                                      overflow: TextOverflow.clip,
                                      style: /*  document!.type ==
                                              MessageType.emoji.name
                                          ? AppCss.manropeSemiBold24
                                              .textColor(
                                                  appCtrl.appTheme.sameWhite)
                                              .letterSpace(.2)
                                              .textHeight(1.2)
                                          : */
                                          AppCss.manropeSemiBold14
                                              .textColor(
                                                  appCtrl.appTheme.sameWhite)
                                              .letterSpace(.2)
                                              .textHeight(1.2)),
                                  const VSpace(Sizes.s8),
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (document!.isFavourite != null)
                                          if (document!.isFavourite == true)
                                            if (appCtrl.user["id"].toString() ==
                                                document!.favouriteId
                                                    .toString())
                                              Icon(Icons.star,
                                                  color: appCtrl
                                                      .appTheme.sameWhite,
                                                  size: Sizes.s10),
                                        const HSpace(Sizes.s3),
                                        if (!isBroadcast)
                                          Icon(Icons.done_all_outlined,
                                              size: Sizes.s15,
                                              color: document!.isSeen == true
                                                  ? appCtrl.appTheme.tick
                                                  : appCtrl.appTheme.sameWhite),
                                        const HSpace(Sizes.s5),
                                        Text(
                                            DateFormat('HH:mm').format(
                                                DateTime
                                                    .fromMillisecondsSinceEpoch(
                                                        int.parse(document!
                                                            .timestamp!))),
                                            style: AppCss.manropeMedium12
                                                .textColor(
                                                    appCtrl.appTheme.sameWhite))
                                      ])
                                ])).paddingOnly(bottom: Insets.i10),
                          ],
                        ),
                      ],

                    )
                  : IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (document!.replyTo != null &&
                              document!.replyTo != "")
                            ReplySenderLayout(document: document),
                          Row(
                            children: [
                              if (document!.isForward != null)
                                if (document!.isForward == true)
                                  if (appCtrl.user["id"].toString() ==
                                      document!.sender.toString())
                                    SvgPicture.asset(eSvgAssets.forward,
                                            height: Sizes.s15)
                                        .paddingSymmetric(horizontal: 10),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Insets.i12,
                                      vertical: Insets.i10),
                                  decoration: ShapeDecoration(
                                      color: appCtrl.appTheme.primary,
                                      shape: SmoothRectangleBorder(
                                          borderRadius: SmoothBorderRadius.only(
                                              topLeft: SmoothRadius(
                                                  cornerRadius: document!.replyTo != null &&
                                                          document!.replyTo !=
                                                              ""
                                                      ? 0
                                                      : 18,
                                                  cornerSmoothing: 1),
                                              topRight: SmoothRadius(
                                                  cornerRadius: document!.replyTo != null &&
                                                          document!.replyTo !=
                                                              ""
                                                      ? 0
                                                      : 18,
                                                  cornerSmoothing: 1),
                                              bottomLeft: const SmoothRadius(
                                                  cornerRadius: 18,
                                                  cornerSmoothing: 1)))),
                                  child: Column(
                                    children: [
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Text(
                                                decryptMessage(
                                                    document!.content),
                                                overflow: TextOverflow.clip,
                                                style: AppCss.manropeSemiBold14
                                                    .textColor(appCtrl
                                                        .appTheme.sameWhite)
                                                    .letterSpace(.2)
                                                    .textHeight(1.2)),
                                            const VSpace(Sizes.s8),
                                            Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  if (document!.isFavourite !=
                                                      null)
                                                    if (document!.isFavourite ==
                                                        true)
                                                      if (appCtrl.user["id"]
                                                              .toString() ==
                                                          document!.favouriteId
                                                              .toString())
                                                        Icon(Icons.star,
                                                            color: appCtrl
                                                                .appTheme
                                                                .sameWhite,
                                                            size: Sizes.s10),
                                                  const HSpace(Sizes.s3),
                                                  if (!isBroadcast)
                                                    Icon(
                                                        Icons.done_all_outlined,
                                                        size: Sizes.s15,
                                                        color: document!
                                                                    .isSeen ==
                                                                true
                                                            ? appCtrl.appTheme
                                                                .sameWhite
                                                            : appCtrl
                                                                .appTheme.tick),
                                                  const HSpace(Sizes.s5),
                                                  Text(
                                                      DateFormat('HH:mm').format(
                                                          DateTime.fromMillisecondsSinceEpoch(
                                                              int.parse(document!
                                                                  .timestamp!))),
                                                      style: AppCss
                                                          .manropeMedium12
                                                          .textColor(appCtrl
                                                              .appTheme
                                                              .sameWhite))
                                                ]),

                                         
                                          ]),
                                    ],
                                  )).paddingOnly(bottom: document!.emoji != null ? Insets.i5 : 0),
                            ],
                          ),
                          if (document!.emojiList != null && document!.emojiList!.isNotEmpty)
                            Row(
                              children: [
                                ...document!.emojiList!.asMap().entries.map(
                                      (e) => Align(

                                       widthFactor: 0.5,
                                      child: EmojiLayout(
                                        emoji: e.value['emoji'],
                                        onTap: emojiTap,
                                      ).paddingOnly(bottom
                                          : 0)),
                                )
                              ],
                            ).paddingSymmetric(
                              horizontal: Insets.i12,
                            )
                        ],
                      ),

                    ),


            ]).marginSymmetric(horizontal: Insets.i15)),

      ],
    );
  }
}
