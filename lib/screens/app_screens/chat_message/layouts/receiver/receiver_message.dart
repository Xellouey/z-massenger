import 'package:chatzy/screens/app_screens/chat_message/layouts/receiver/receiver_content.dart';
import 'package:chatzy/screens/app_screens/chat_message/layouts/receiver/receiver_image.dart';

import '../../../../../config.dart';
import '../../../../../widgets/common_link_layout.dart';
import '../../on_tap_function_class.dart';
import '../audio_doc.dart';
import '../contact_layout.dart';
import '../doc_image.dart';
import '../docx_layout.dart';
import '../excel_layout.dart';
import '../gif_layout.dart';
import '../location_layout.dart';
import '../pdf_layout.dart';
import '../receiver_image.dart';
import '../video_doc.dart';

class ReceiverMessage extends StatefulWidget {
  final MessageModel? document;
  final int? index;
  final String? docId, title;
  final bool isGroup;

  const ReceiverMessage({
    super.key,
    this.index,
    this.document,
    this.docId,
    this.isGroup = false,
    this.title,
  });

  @override
  State<ReceiverMessage> createState() => _ReceiverMessageState();
}

class _ReceiverMessageState extends State<ReceiverMessage> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(builder: (chatCtrl) {
      return Stack(children: [
        Container(
            color: chatCtrl.selectedIndexId.contains(widget.docId)
                ? Color(0xFF2F4F4F)
                : appCtrl.appTheme.trans,
            margin: const EdgeInsets.only(bottom: Insets.i10),
            padding: EdgeInsets.only(
                left: Insets.i20,
                right: Insets.i20,
                top: chatCtrl.selectedIndexId.contains(widget.docId)
                    ? Insets.i10
                    : 0),
            child: Row(children: [
              ReceiverChatImage(id: chatCtrl.pId),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        // MESSAGE BOX FOR TEXT
                        if (widget.document!.type == MessageType.text.name ||
                            widget.document!.type == MessageType.emoji.name)
                          ReceiverContent(
                              emojiTap: () => OnTapFunctionCall().onEmojiRemove(
                                  chatCtrl,
                                  widget.docId,
                                  "",
                                  widget.title,
                                  widget.document!.content),
                              onLongPress: () => chatCtrl.onLongPressFunction(
                                  widget.docId, widget.title, widget.document!),
                              document: widget.document,
                              onTap: () => OnTapFunctionCall()
                                  .contentTap(chatCtrl, widget.docId)),

                        // MESSAGE BOX FOR IMAGE
                        if (widget.document!.type == MessageType.image.name)
                          ReceiverImage(
                              emojiTap: () => OnTapFunctionCall().onEmojiRemove(
                                  chatCtrl,
                                  widget.docId,
                                  "",
                                  widget.title,
                                  widget.document!.content),
                              onTap: () => OnTapFunctionCall().imageTap(
                                  chatCtrl, widget.docId, widget.document),
                              document: widget.document,
                              onLongPress: () => chatCtrl.onLongPressFunction(
                                  widget.docId,
                                  widget.title,
                                  widget.document!)),

                        if (widget.document!.type == MessageType.contact.name)
                          ContactLayout(
                              emojiTap: () => OnTapFunctionCall().onEmojiRemove(
                                  chatCtrl,
                                  widget.docId,
                                  "",
                                  widget.title,
                                  widget.document!.content),
                              isReceiver: true,
                              onTap: () => OnTapFunctionCall()
                                  .contentTap(chatCtrl, widget.docId),
                              onLongPress: () => chatCtrl.onLongPressFunction(
                                  widget.docId, widget.title, widget.document!),
                              document: widget.document),
                        if (widget.document!.type == MessageType.location.name)
                          LocationLayout(
                              emojiTap: () => OnTapFunctionCall().onEmojiRemove(
                                  chatCtrl,
                                  widget.docId,
                                  "",
                                  widget.title,
                                  widget.document!.content),
                              isReceiver: true,
                              document: widget.document,
                              onLongPress: () => chatCtrl.onLongPressFunction(
                                  widget.docId, widget.title, widget.document!),
                              onTap: () => OnTapFunctionCall().locationTap(
                                  chatCtrl, widget.docId, widget.document)),
                        if (widget.document!.type == MessageType.video.name)
                          VideoDoc(
                              duration: (p0) {
                                chatCtrl.videoDuration = p0;
                                chatCtrl.update();
                              },
                              emojiTap: () => OnTapFunctionCall().onEmojiRemove(
                                  chatCtrl,
                                  widget.docId,
                                  "",
                                  widget.title,
                                  widget.document!.content),
                              document: widget.document,
                              onLongPress: () => chatCtrl.onLongPressFunction(
                                  widget.docId, widget.title, widget.document!),
                              isReceiver: true,
                              onTap: () => OnTapFunctionCall().locationTap(
                                  chatCtrl, widget.docId, widget.document)),
                        if (widget.document!.type! == MessageType.audio.name)
                          AudioDoc(
                              duration: (p0) {
                                chatCtrl.audioDuration = p0;
                                chatCtrl.update();
                              },
                              emojiTap: () => OnTapFunctionCall().onEmojiRemove(
                                  chatCtrl,
                                  widget.docId,
                                  "",
                                  widget.title,
                                  widget.document!.content),
                              isReceiver: true,
                              document: widget.document,
                              onTap: () => OnTapFunctionCall()
                                  .contentTap(chatCtrl, widget.docId),
                              onLongPress: () => chatCtrl.onLongPressFunction(
                                  widget.docId,
                                  widget.title,
                                  widget.document!)),
                        if (widget.document!.type == MessageType.doc.name)
                          (decryptMessage(widget.document!.content)
                                  .contains(".pdf"))
                              ? PdfLayout(
                                  isReceiver: true,
                                  emojiTap: () => OnTapFunctionCall().onEmojiRemove(
                                      chatCtrl,
                                      widget.docId,
                                      "",
                                      widget.title,
                                      widget.document!.content),
                                  document: widget.document,
                                  onTap: () => OnTapFunctionCall().pdfTap(
                                      chatCtrl, widget.docId, widget.document),
                                  onLongPress: () => chatCtrl.onLongPressFunction(
                                      widget.docId,
                                      widget.title,
                                      widget.document!))
                              : (decryptMessage(widget.document!.content)
                                      .contains(".doc"))
                                  ? DocxLayout(
                                      isReceiver: true,
                                      emojiTap: () => OnTapFunctionCall().onEmojiRemove(
                                          chatCtrl,
                                          widget.docId,
                                          "",
                                          widget.title,
                                          widget.document!.content),
                                      document: widget.document,
                                      onTap: () => OnTapFunctionCall().docTap(
                                          chatCtrl,
                                          widget.docId,
                                          widget.document),
                                      onLongPress: () => chatCtrl.onLongPressFunction(
                                          widget.docId, widget.title, widget.document!))
                                  : (decryptMessage(widget.document!.content).contains(".xlsx"))
                                      ? ExcelLayout(
                                          isReceiver: true,
                                          emojiTap: () => OnTapFunctionCall()
                                              .onEmojiRemove(
                                                  chatCtrl,
                                                  widget.docId,
                                                  "",
                                                  widget.title,
                                                  widget.document!.content),
                                          onTap: () => OnTapFunctionCall()
                                              .excelTap(chatCtrl, widget.docId,
                                                  widget.document),
                                          onLongPress: () =>
                                              chatCtrl.onLongPressFunction(
                                                  widget.docId,
                                                  widget.title,
                                                  widget.document!),
                                          document: widget.document,
                                        )
                                      : (decryptMessage(widget.document!.content).contains(".jpg") || decryptMessage(widget.document!.content).contains(".png") || decryptMessage(widget.document!.content).contains(".heic") || decryptMessage(widget.document!.content).contains(".jpeg"))
                                          ? DocImageLayout(isReceiver: true, emojiTap: () => OnTapFunctionCall().onEmojiRemove(chatCtrl, widget.docId, "", widget.title, widget.document!.content), onTap: () => OnTapFunctionCall().docImageTap(chatCtrl, widget.docId, widget.document), document: widget.document, onLongPress: () => chatCtrl.onLongPressFunction(widget.docId, widget.title, widget.document!))
                                          : Container(),
                        if (widget.document!.type == MessageType.link.name)
                          CommonLinkLayout(
                              isReceiver: true,
                              document: widget.document,
                              onRemoveEmoji: () => OnTapFunctionCall()
                                  .onEmojiRemove(chatCtrl, widget.docId, "",
                                      widget.title, widget.document!.content),
                              onTap: () => OnTapFunctionCall().onTapLink(
                                  chatCtrl, widget.docId, widget.document),
                              onLongPress: () => chatCtrl.onLongPressFunction(
                                  widget.docId,
                                  widget.title,
                                  widget.document!)),
                        if (widget.document!.type == MessageType.gif.name)
                          GifLayout(
                              isReceiver: true,
                              emojiTap: () => OnTapFunctionCall().onEmojiRemove(
                                  chatCtrl,
                                  widget.docId,
                                  "",
                                  widget.title,
                                  widget.document!.content),
                              onTap: () => OnTapFunctionCall()
                                  .contentTap(chatCtrl, widget.docId),
                              document: widget.document,
                              onLongPress: () => chatCtrl.onLongPressFunction(
                                  widget.docId, widget.title, widget.document!))
                      ],
                    ),
                    if (widget.document!.type == MessageType.messageType.name)
                      Align(
                              alignment: Alignment.center,
                              child: Text(
                                      decryptMessage(widget.document!.content))
                                  .paddingSymmetric(
                                      horizontal: Insets.i8,
                                      vertical: Insets.i10)
                                  .decorated(
                                      color: appCtrl.appTheme.primary
                                          .withOpacity(.2),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.r8))
                                  .alignment(Alignment.center))
                          .paddingOnly(bottom: Insets.i8)
                  ])
            ])),
        if (chatCtrl.enableReactionPopup &&
            chatCtrl.selectedIndexId.contains(widget.docId))
          SizedBox(
              height: Sizes.s48,
              child: ReactionPopup(
                reactionPopupConfig: ReactionPopupConfiguration(
                    shadow:
                        BoxShadow(color: Colors.grey.shade400, blurRadius: 20)),
                onEmojiTap: (val) => OnTapFunctionCall().onEmojiSelect(chatCtrl,
                    widget.docId, val, widget.title, widget.document!.content),
                showPopUp: chatCtrl.showPopUp,
              ))
      ]);
    });
  }
}
