
import 'package:intl/intl.dart';
import '../../../../../config.dart';

class SenderImage extends StatelessWidget {
  final MessageModel? document;
  final VoidCallback? onPressed, onLongPress,emojiTap;
  final bool isBroadcast;
  final String? userId;

  const   SenderImage({super.key, this.document,this.emojiTap, this.onPressed, this.onLongPress,this.isBroadcast =false,this.userId})
     ;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        InkWell(
            onLongPress: onLongPress,
            onTap:onPressed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (document!.replyTo != null && document!.replyTo != "")
                  Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: Sizes.s10, horizontal: Insets.i12),
                      decoration: ShapeDecoration(
                          color: appCtrl.appTheme.greyText.withOpacity(0.2),
                          shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius.only(
                                  topLeft: SmoothRadius(
                                      cornerRadius: document!.replyTo != null &&
                                          document!.replyTo != ""
                                          ? 18
                                          : 0,
                                      cornerSmoothing: 1),
                                  topRight: SmoothRadius(
                                      cornerRadius: document!.replyTo != null &&
                                          document!.replyTo != ""
                                          ? 18
                                          : 0,
                                      cornerSmoothing: 1)))),
                      child: IntrinsicHeight(
                          child:
                         Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                VerticalDivider(
                                    color: appCtrl.appTheme.primary, width: 0),
                                const HSpace(Sizes.s10),
                                Text(decryptMessage(document!.replyTo),
                                    overflow: TextOverflow.clip,
                                    style: document!.type == MessageType.emoji.name
                                        ? AppCss.manropeSemiBold14
                                        .textColor(appCtrl.appTheme.redColor)
                                        .letterSpace(.2)
                                        .textHeight(1.2)
                                        : AppCss.manropeSemiBold14
                                        .textColor(appCtrl.appTheme.redColor)
                                        .letterSpace(.2)
                                        .textHeight(1.2))
                              ]))),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: Insets.i10,),
                  decoration: ShapeDecoration(
                    color: appCtrl.appTheme.primary,
                    shape:  SmoothRectangleBorder(
                        borderRadius:SmoothBorderRadius(cornerRadius: 20,cornerSmoothing: 1)),
                  ),
                  child: ClipSmoothRect(
                    clipBehavior: Clip.hardEdge,
                    radius: SmoothBorderRadius(
                      cornerRadius: 20,
                      cornerSmoothing: 1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Material(
                          borderRadius: SmoothBorderRadius(cornerRadius: 15,cornerSmoothing: 1),
                          clipBehavior: Clip.hardEdge,
                          child: CachedNetworkImage(
                            placeholder: (context, url) => Container(
                                width: Sizes.s160,

                                decoration: ShapeDecoration(
                                  color: appCtrl.appTheme.primary,
                                  shape:  SmoothRectangleBorder(
                                      borderRadius:SmoothBorderRadius(cornerRadius: 10,cornerSmoothing: 1)),
                                ),
                                child:Center(child: CircularProgressIndicator(color: appCtrl.appTheme.sameWhite,strokeWidth: 3))),
                            imageUrl: decryptMessage(document!.content),
                            width: Sizes.s160,

                            fit: BoxFit.fill
                          ),
                        ).padding(horizontal:Insets.i10,top: Insets.i10),
                        Row(

                          children: [
                            if (document!.isFavourite != null)
                              if (document!.isFavourite == true)
                                if(appCtrl.user["id"].toString() == document!.favouriteId.toString())
                                Icon(Icons.star,
                                    color: appCtrl.appTheme.sameWhite, size: Sizes.s10),
                            const HSpace(Sizes.s3),
                            if (!isBroadcast)
                              Icon(Icons.done_all_outlined,
                                  size: Sizes.s15,
                                  color: document!.isSeen == true
                                      ? appCtrl.appTheme.sameWhite
                                      : appCtrl.appTheme.tick),
                            const HSpace(Sizes.s5),
                            Text(
                              DateFormat('HH:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(document!.timestamp!))),
                              style: AppCss.manropeMedium12
                                  .textColor(appCtrl.appTheme.sameWhite),
                            )
                          ],
                        ).paddingAll(Insets.i10)
                      ],
                    ),
                  ),
                ),

              ],
            )).paddingOnly(bottom: Insets.i10),
        if (document!.emojiList != null && document!.emojiList!.isNotEmpty)
          Row(

            children: [...document!.emojiList!.asMap().entries.map((e) => Align(

                widthFactor: 0.5,child: EmojiLayout(emoji: e.value['emoji'],onTap: emojiTap,)),)],
          )
      ],
    );
  }
}
