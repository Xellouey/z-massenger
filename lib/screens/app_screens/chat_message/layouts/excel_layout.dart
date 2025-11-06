import 'package:chatzy/screens/app_screens/chat_message/layouts/sender/reply_sender_layout.dart';

import '../../../../config.dart';
import '../../../../utils/broadcast_class.dart';
import 'doc_content.dart';

class ExcelLayout extends StatelessWidget {
  final MessageModel? document;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onTap, emojiTap;
  final bool isReceiver, isGroup, isBroadcast;
  final String? currentUserId;

  const ExcelLayout(
      {super.key,
      this.document,
      this.onLongPress,
      this.emojiTap,
      this.isReceiver = false,
      this.isGroup = false,
      this.currentUserId,
      this.onTap,
      this.isBroadcast = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onLongPress: onLongPress,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IntrinsicWidth(
              child: Column(
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
                          DocContent(
                              isReceiver: isReceiver,
                              isBroadcast: isBroadcast,
                              document: document,
                              currentUserId: currentUserId,
                              isGroup: isGroup),
                          const VSpace(Sizes.s2),
                          BroadcastClass().timeFavouriteLayout(
                              document!.isFavourite ?? false,
                              document!.timestamp,
                              isGroup,
                              isReceiver,
                              isBroadcast,
                              document!.isSeen != null
                                  ? document!.isSeen!
                                  : false,
                              document!.favouriteId.toString())
                        ],
                      )
                          .paddingAll(Insets.i8)
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
                          .marginSymmetric(
                              horizontal: Insets.i10, vertical: Insets.i5),
                    ],
                  ),
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
          ],
        ));
  }
}
