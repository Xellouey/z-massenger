import 'dart:developer';

import 'package:intl/intl.dart';

import '../../../../../config.dart';

class ReplySenderLayout extends StatelessWidget {
  final MessageModel? document;
  final bool isGroup
  ;

  const ReplySenderLayout({super.key, this.document, this.isGroup = false});

  @override
  Widget build(BuildContext context) {
    var ishold = Get.put(GroupChatMessageController);

    return Container(
        padding: const EdgeInsets.symmetric(
            vertical: Sizes.s10, horizontal: Insets.i12),
        decoration: ShapeDecoration(
             color: appCtrl.appTheme.greyText.withOpacity(0.4),
            shape: SmoothRectangleBorder(
              borderRadius: isGroup?

              SmoothBorderRadius.all(SmoothRadius(cornerRadius: document!.replyType != null ||
                   document!.replyType != ""
                       ? 18
                    : 0, cornerSmoothing: 1))

                  : SmoothBorderRadius.only(
                  topLeft: SmoothRadius(
                      cornerRadius: document!.replyType != null ||
                              document!.replyType != ""
                          ? 18
                          : 0,
                      cornerSmoothing: 1),
                  topRight: SmoothRadius(
                      cornerRadius: document!.replyType != null ||
                              document!.replyType != ""
                          ? 18
                          : 0,
                      cornerSmoothing: 1)),

            )),
        child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // if(isGroup == true)
                //   Text(
                //     "Replying to: ${document!.originalSenderName?.isNotEmpty == true
                //         ? document!.originalSenderName
                //         : document!.replyBy}",
                //     style: TextStyle(fontWeight: FontWeight.bold),
                //   ),
                  // Text(
                  //   document?.originalSenderName ?? "You",
                  //   style: AppCss.manropeBold14.textColor(appCtrl.appTheme.white),
                  // ),
                Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      VerticalDivider(color: appCtrl.appTheme.primary, width: 0),
                      const HSpace(Sizes.s10),
                      document!.replyType == MessageType.audio.name ||
                              document!.replyType == MessageType.video.name
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    document!.replyType == MessageType.audio.name
                                        ? appFonts.audio.tr
                                        : appFonts.video.tr,
                                    style: AppCss.manropeMedium16
                                        .textColor(appCtrl.appTheme.darkText)),
                              ],
                            )
                          // : Container(height: Sizes.s10,width: Sizes.s300,color: Colors.red,),
                          : document!.replyType == MessageType.image.name ||
                                  document!.replyType == MessageType.gif.name
                              ? document!.replyType == MessageType.image.name
                                  ? Text(appFonts.image.tr)
                                  : Text("gif")
                              : document!.replyType == MessageType.contact.name
                                  ? Text(
                                      "${appFonts.contact.tr} : ${decryptMessage(document!.replyTo).split('-BREAK-')[0]}")
                                  : document!.replyType == MessageType.doc.name
                                      ? Text(decryptMessage(document!.replyTo)
                                          .split('-BREAK-')[0])
                                      : decryptMessage(document!.replyTo).length >
                                              40
                                          ? Text(decryptMessage(document!.replyTo),
                                                  overflow: TextOverflow.clip,
                                                  style: document!.replyType ==
                                                          MessageType.emoji.name
                                                      ? AppCss.manropeSemiBold14.textColor(appCtrl.appTheme.darkText).letterSpace(.2).textHeight(
                                                          1.2)
                                                      : AppCss.manropeSemiBold14.textColor(appCtrl.appTheme.darkText).letterSpace(.2).textHeight(
                                                          1.2))
                                              .width(Sizes.s200)
                                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(decryptMessage(document!.replyTo),
                                                  overflow: TextOverflow.clip,
                                                  style: document!.replyType == MessageType.emoji.name
                                                      ? AppCss.manropeSemiBold14
                                                          .textColor(appCtrl.appTheme.white)
                                                          .letterSpace(.2)
                                                          .textHeight(1.2)
                                                      : AppCss.manropeSemiBold14.textColor(appCtrl.appTheme.sameWhite).letterSpace(.2).textHeight(1.2)),
                                               SizedBox(height: 1,width: Sizes.s60,)

                                            ]
                                          )
                    ]),
                if (document!.replyType == MessageType.image.name ||
                    document!.replyType == MessageType.gif.name)
                  CachedNetworkImage(
                      imageUrl: decryptMessage(document!.replyTo)!,
                      imageBuilder: (context, imageProvider) => Container(
                          height: 40,
                          width: 40,
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(
                              shape: SmoothRectangleBorder(
                                  borderRadius: SmoothBorderRadius(
                                      cornerRadius: 5, cornerSmoothing: 1)),
                              image: DecorationImage(
                                  fit: BoxFit.cover, image: imageProvider))),
                      errorWidget: (context, url, error) => Container(
                            height: 40,
                            width: 40,
                            alignment: Alignment.center,
                            decoration: ShapeDecoration(
                                shape: SmoothRectangleBorder(
                                    borderRadius: SmoothBorderRadius(
                                        cornerRadius: 5, cornerSmoothing: 1)),
                                color: appCtrl.appTheme.tick),
                          )).marginSymmetric(horizontal: Sizes.s10)
                          ],
                        ),
              ],
            )));
  }
}

