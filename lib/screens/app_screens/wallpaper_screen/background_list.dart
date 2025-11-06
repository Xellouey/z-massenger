import 'dart:developer';

import '../../../config.dart';
import '../../../widgets/common_app_bar.dart';
import 'layouts/wallpaper_layout.dart';

class BackgroundList extends StatefulWidget {
  const BackgroundList({super.key});

  @override
  State<BackgroundList> createState() => _BackgroundListState();
}

class _BackgroundListState extends State<BackgroundList> {
  String? chatId, groupId, broadcastId;

  @override
  void initState() {
    var data = Get.arguments;
    if (data["chatId"] != null) {
      chatId = data["chatId"];
      log("chat walpaer id ${chatId}");
    }
    if (data["groupId"] != null) {
      groupId = data["groupId"];
    }
    if (data["broadcastId"] != null) {
      broadcastId = data["broadcastId"];
    }
    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DirectionalityRtl(
      child: Scaffold(
        backgroundColor: appCtrl.appTheme.screenBG,
        appBar: CommonAppBar(text: appFonts.defaultWallpaper.tr),
        body: Column(

          children: [
            Text("remove Bg: ").inkWell(),
            ListView(
              children: [
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection(collectionName.wallpaper)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Container();
                    } else if (snapshot.hasData) {
                      if (snapshot.data != null && snapshot.data!.docs.isNotEmpty) {
                        return Column(
                          children: [
                            ...snapshot.data!.docs.asMap().entries.map((e) {
                              List image = e.value['image'];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (e.key != 0) const VSpace(Sizes.s15),
                                  Text(e.value['type'].toString().capitalizeFirst!,
                                      style: AppCss.manropeBold14
                                          .textColor(appCtrl.appTheme.darkText)),
                                  const VSpace(Sizes.s15),
                                  WallpaperLayout(
                                    wallpaperList: image,
                                    chatId: chatId,
                                    groupId: groupId,
                                    // broadcastId: broadcastId,
                                  )
                                ],
                              );
                            })
                          ],
                        );
                      } else {
                        return Container();
                      }
                    } else {
                      return Container();
                    }
                  },
                ),
              ],
            ).paddingSymmetric(horizontal: Insets.i20),
          ],
        ),
      ),
    );
  }
}
