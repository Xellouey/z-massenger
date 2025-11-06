import '../../../../config.dart';

class GroupCardSubTitle extends StatelessWidget {
  final DocumentSnapshot? document;
  final String? name, currentUserId;
  final bool hasData;

  const GroupCardSubTitle({
    super.key,
    this.document,
    this.name,
    this.currentUserId,
    this.hasData = false,
  });

  @override
  Widget build(BuildContext context) {
    if (document == null || !document!.exists) return const SizedBox();

    final data = document!.data() as Map<String, dynamic>;
    final String lastMessage = data["lastMessage"] ?? "";
    final bool isSender = currentUserId == data["senderId"];
    final String decryptedMsg = lastMessage.isNotEmpty ? decryptMessage(lastMessage) : "";

    final bool isGif = decryptedMsg.contains(".gif");
    final bool isMedia = decryptedMsg.contains("media");
    final bool isFile = decryptedMsg.contains(".pdf") ||
        decryptedMsg.contains(".doc") ||
        decryptedMsg.contains(".mp3") ||
        decryptedMsg.contains(".mp4") ||
        decryptedMsg.contains(".xlsx") ||
        decryptedMsg.contains(".ods");

    // Display message logic
    String displayMessage = "";
    if (decryptedMsg.isEmpty) {
      if (isSender) {
        displayMessage = "You created this group ${data["group"]?["name"] ?? ""}";
      } else {
        displayMessage = "${data["sender"]?["name"] ?? "Someone"} added you";
      }
    } else if (isMedia) {
      displayMessage = hasData ? "$name Media Share" : "Media Share";
    } else if (isFile) {
      displayMessage = decryptedMsg.split("-BREAK-")[0];
    } else {
      displayMessage = decryptedMsg;
    }

    return Row(
      children: [
        if (isSender && lastMessage.isNotEmpty)
          Icon(
            Icons.done_all,
            color: appCtrl.isTheme
                ? appCtrl.appTheme.white
                : appCtrl.appTheme.greyText,
            size: Sizes.s16,
          ),
        if (isSender && lastMessage.isNotEmpty)
          const HSpace(Sizes.s5),
        if (lastMessage.isNotEmpty)
          isGif
              ? const Icon(Icons.gif_box, size: Sizes.s20).alignment(Alignment.centerLeft)
              : SizedBox(
            width: Sizes.s150,
            child: Text(
              displayMessage,
              overflow: TextOverflow.ellipsis,
              style: AppCss.manropeMedium12
                  .textColor(appCtrl.appTheme.greyText)
                  .textHeight(1.2)
                  .letterSpace(.2),
            ).width(Sizes.s170),
          ),
      ],
    );
  }
}
