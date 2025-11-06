import 'dart:developer';

import '../../../../config.dart';

class DeleteAlert extends StatelessWidget {
  final DocumentSnapshot? documentReference;

  const DeleteAlert({super.key, this.documentReference});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(builder: (chatCtrl) {
      return AlertDialog(
        backgroundColor: appCtrl.appTheme.screenBG,
        title: Text(appFonts.alert.tr),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                title: Text(appFonts.deleteFromMe),
                leading: Radio(
                  value: "fromMe",
                  groupValue: chatCtrl.deleteOption,
                  onChanged: (String? value) {
                    chatCtrl.deleteOption = value;
                    chatCtrl.update();
                  },
                ),
              ),
              ListTile(
                title:  Text(appFonts.deleteFromAll),
                leading: Radio(
                  value: "forAll",
                  groupValue: chatCtrl.deleteOption,
                  onChanged: (String? value) {
                    chatCtrl.deleteOption = value;
                    chatCtrl.update();
                  },
                ),
              ),
            ]),
        actions: <Widget>[
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
          TextButton(
            onPressed: () async {
              chatCtrl.deleteChat();
            },
            child: const Text('Yes'),
          ),
        ],
      );
    });
  }
}
