import 'dart:developer';

import 'package:dart_emoji/dart_emoji.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:chatzy/common/session.dart';
import '../../../../config.dart';
import '../../chat_message/layouts/reply_to.dart';

class GroupInputBox extends StatelessWidget {
  const GroupInputBox({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GroupChatMessageController>(builder: (chatCtrl) {
      final isReplying = chatCtrl.replyMessage != null;

      return Row(children: [
        Expanded(
            child: Column(
          children: [
            if (isReplying)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          height: MediaQuery.of(context).size.height / 20,
                          width: Sizes.s3,
                          color: appCtrl.appTheme.primary),
                      const HSpace(Sizes.s10),
                      // Session().senderName = chatCtrl.replyMessage!.senderName!,
                      Expanded(
                          child: Column(
                        children: [
                          Text(chatCtrl.replyMessage!.senderName??''.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                              '${decryptMessage(chatCtrl.replyMessage!.content)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )),
                      // if (onCancelReply != null)
                      GestureDetector(
                          onTap: () => chatCtrl.cancelReply(),
                          child: Icon(Icons.close,
                              size: 16, color: appCtrl.appTheme.primary))
                    ])
              ])
                  .paddingAll(Sizes.s12)
                  .decorated(
                      color: const Color(0xff7F83841A).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(Sizes.s10))
                  .padding(bottom: Sizes.s6),
            Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                height: Sizes.s55,
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xff2c2c14).withOpacity(0.08),
                          blurRadius: 4,
                          spreadRadius: 1)
                    ],
                    border: Border.all(
                        color: const Color.fromRGBO(49, 100, 189, 0.1),
                        width: 1),
                    color: appCtrl.appTheme.white),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SvgPicture.asset(eSvgAssets.emojis, height: Sizes.s22)
                          .inkWell(onTap: () {
                        chatCtrl.pickerCtrl.dismissKeyboard();
                        chatCtrl.isShowSticker = !chatCtrl.isShowSticker;
                        log("SHOW ${chatCtrl.isShowSticker}");
                        chatCtrl.update();
                      }).paddingSymmetric(horizontal: Insets.i10),
                      Flexible(
                          child: TextFormField(
                        minLines: 1,
                        maxLines: 5,
                        style: TextStyle(
                            color: appCtrl.appTheme.darkText, fontSize: 15.0),
                        controller: chatCtrl.textEditingController,
                        decoration: InputDecoration.collapsed(
                            hintText: appFonts.writeHere.tr,
                            hintStyle:
                                TextStyle(color: appCtrl.appTheme.greyText)),
                        enableInteractiveSelection: false,
                        keyboardType: TextInputType.text,
                        onTap: () {
                          chatCtrl.isShowSticker = false;
                          chatCtrl.update();
                        },
                        onChanged: (val) {
                          bool isCheck = EmojiUtil.hasOnlyEmojis(val);
                          if (isCheck) {
                            chatCtrl.isEmoji = true;
                          }
                          chatCtrl.isShowSticker = false;
                          if (chatCtrl.textEditingController.text.isNotEmpty) {
                            if (val.contains(".gif")) {
                              chatCtrl.onSendMessage(val, MessageType.gif);
                              chatCtrl.textEditingController.clear();
                            }
                          }
                        },
                      ).inkWell(onTap: () => chatCtrl.isShowSticker = false)),
                      if (chatCtrl.textEditingController.text.isEmpty)
                        Row(children: [
                          SvgPicture.asset(eSvgAssets.clip).inkWell(
                              onTap: () => chatCtrl.shareMedia(context)),
                          const HSpace(Sizes.s10),
                          InkWell(
                              child: SvgPicture.asset(eSvgAssets.gif),
                              onTap: () async {
                                if (chatCtrl.isShowSticker = true) {
                                  chatCtrl.isShowSticker = false;
                                  chatCtrl.update();
                                }
                                GiphyGif? gif = await GiphyGet.getGif(
                                    tabColor: appCtrl.appTheme.primary,
                                    context: context,
                                apiKey: appCtrl.userAppSettingsVal?.gifAPI?.isNotEmpty == true 
                                    ? appCtrl.userAppSettingsVal!.gifAPI! 
                                    : "3WluNlptyohu3wRObgyuVbw1hWbE5A99",
                                    lang: GiphyLanguage.english);
                                if (gif != null) {
                                  chatCtrl.onSendMessage(
                                      gif.images!.original!.url,
                                      MessageType.gif);
                                }
                              })
                        ]),
                      GestureDetector(
                        onTap: () {
                          if (chatCtrl.textEditingController.text.isNotEmpty) {
                            chatCtrl.onSendMessage(
                                chatCtrl.textEditingController.text,
                                chatCtrl.textEditingController.text
                                            .contains("https://") ||
                                        chatCtrl.textEditingController.text
                                            .contains("http://")
                                    ? chatCtrl.isEmoji
                                        ? MessageType.emoji
                                        : MessageType.link
                                    : MessageType.text);
                          }
                        },
                        onLongPress: () {
                          if (chatCtrl.textEditingController.text.isEmpty) {
                            chatCtrl.checkPermission("audio", 0);
                          }
                        },
                        child: Container(
                                height: Sizes.s50,
                                padding: const EdgeInsets.symmetric(
                                  vertical: Insets.i10,
                                ),
                                decoration: ShapeDecoration(
                                    gradient: RadialGradient(colors: [
                                      appCtrl.isTheme
                                          ? appCtrl.appTheme.primary
                                              .withOpacity(.8)
                                          : appCtrl.appTheme.primary,
                                      appCtrl.appTheme.primary
                                    ]),
                                    shape: SmoothRectangleBorder(
                                        borderRadius: SmoothBorderRadius(
                                            cornerRadius: 12,
                                            cornerSmoothing: 1))),
                                child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: SvgPicture.asset(
                                        chatCtrl.textEditingController.text
                                                .isNotEmpty
                                            ? eSvgAssets.send
                                            : eSvgAssets.microphone,
                                        colorFilter: ColorFilter.mode(
                                            appCtrl.appTheme.sameWhite,
                                            BlendMode.srcIn))))
                            .paddingSymmetric(vertical: Insets.i5)
                            .paddingSymmetric(horizontal: Insets.i10),
                      )
                    ])),
          ],
        ))
      ]);
    });
  }
}
