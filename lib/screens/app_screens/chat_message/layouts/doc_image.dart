import 'package:chatzy/screens/app_screens/chat_message/layouts/sender/reply_sender_layout.dart';
import 'package:intl/intl.dart';
import '../../../../config.dart';

class DocImageLayout extends StatelessWidget {
  final MessageModel? document;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onTap, emojiTap;
  final bool isReceiver, isGroup, isBroadcast;
  final String? currentUserId;

  const DocImageLayout(
      {super.key,
      this.document,
      this.onLongPress,
      this.emojiTap,
      this.isReceiver = false,
      this.isGroup = false,
      this.currentUserId,
      this.isBroadcast = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
        alignment: appCtrl.isRTL || appCtrl.languageVal == "ar"
            ? Alignment.bottomRight
            : Alignment.bottomLeft,
        children: [
          InkWell(
            onLongPress: onLongPress,
            onTap: onTap,
            child: IntrinsicWidth(
              child: Column(
                      crossAxisAlignment: isReceiver
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                    if (document!.sender == appCtrl.user['id'])
                      if (document!.replyTo != null && document!.replyTo != "")
                        ReplySenderLayout(
                          document: document,
                          isGroup: isGroup,
                        ),
                    Row(
                      children: [
                        if (document!.isForward != null)
                          if (document!.isForward == true)
                            if (appCtrl.user["id"].toString() ==
                                document!.sender.toString())
                              SvgPicture.asset(eSvgAssets.forward,
                                      height: Sizes.s15)
                                  .paddingSymmetric(horizontal: 10),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isGroup)
                                if (isReceiver)
                                  if (document!.sender != currentUserId)
                                    Column(children: [
                                      Text(document!.senderName!,
                                              style: AppCss.manropeMedium12
                                                  .textColor(
                                                      appCtrl.appTheme.primary))
                                          .paddingAll(Insets.i10)
                                    ]),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(children: [
                                      Image.asset(eImageAssets.jpg,
                                          height: Sizes.s20),
                                      const HSpace(Sizes.s10),
                                      Expanded(
                                          child: Text(
                                              decryptMessage(document!.content)
                                                  .split("-BREAK-")[0],
                                              textAlign: TextAlign.start,
                                              style: AppCss.manropeMedium12
                                                  .textColor(isReceiver
                                                      ? appCtrl
                                                          .appTheme.darkText
                                                      : appCtrl
                                                          .appTheme.sameWhite)))
                                    ])
                                        .width(190)
                                        .paddingSymmetric(
                                            horizontal: Insets.i10,
                                            vertical: Insets.i10)
                                        .decorated(
                                            color: isReceiver
                                                ? appCtrl.appTheme.borderColor
                                                : appCtrl.appTheme.primary,
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.r8)),
                                    const VSpace(Sizes.s2),
                                    IntrinsicHeight(
                                        child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                          if (!isGroup)
                                            if (!isReceiver && !isBroadcast)
                                              Icon(Icons.done_all_outlined,
                                                  size: Sizes.s15,
                                                  color: document!.isSeen ==
                                                          true
                                                      ? appCtrl
                                                          .appTheme.sameWhite
                                                      : appCtrl.appTheme.tick),
                                          const HSpace(Sizes.s5),
                                          IntrinsicHeight(
                                              child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
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
                                                          color: isReceiver
                                                              ? appCtrl.appTheme
                                                                  .greyText
                                                              : appCtrl.appTheme
                                                                  .greyText,
                                                          size: Sizes.s10),
                                                const HSpace(Sizes.s3),
                                                Text(
                                                    DateFormat('HH:mm').format(
                                                        DateTime.fromMillisecondsSinceEpoch(
                                                            int.parse(document!
                                                                .timestamp!))),
                                                    style: AppCss
                                                        .manropeMedium12
                                                        .textColor(isReceiver
                                                            ? appCtrl.appTheme
                                                                .greyText
                                                            : appCtrl.appTheme
                                                                .sameWhite))
                                              ]))
                                        ]).paddingOnly(top: Insets.i5))
                                  ]).paddingAll(Insets.i8)
                            ]),
                      ],
                    )
                  ])
                  .decorated(
                      color: isReceiver
                          ? appCtrl.appTheme.borderColor
                          : appCtrl.appTheme.primary,
                      borderRadius: SmoothBorderRadius.only(
                          topLeft: SmoothRadius(
                              cornerRadius: document!.replyTo != null &&
                                      document!.replyTo != ""
                                  ? 0
                                  : 8,
                              cornerSmoothing: 1),
                          topRight: SmoothRadius(
                              cornerRadius: document!.replyTo != null &&
                                      document!.replyTo != ""
                                  ? 0
                                  : 8,
                              cornerSmoothing: 1),
                          bottomLeft: const SmoothRadius(
                              cornerRadius: 8, cornerSmoothing: 1)))
                  .marginSymmetric(horizontal: Insets.i14),
            ),
          ).paddingOnly(bottom: Insets.i10),
          if (document!.emojiList != null && document!.emojiList!.isNotEmpty)
            Row(children: [
              ...document!.emojiList!.asMap().entries.map((e) => Align(
                  widthFactor: 0.5,
                  child: EmojiLayout(emoji: e.value['emoji'], onTap: emojiTap)
                      .paddingOnly(bottom: Sizes.s2)))
            ])
        ]).paddingOnly(bottom: Insets.i5);
  }
}
