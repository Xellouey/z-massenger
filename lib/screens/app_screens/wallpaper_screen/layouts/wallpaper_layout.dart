import 'dart:developer';

import '../../../../config.dart';
class WallpaperLayout extends StatelessWidget {
  final List? wallpaperList;
  final String? chatId;
  final String? groupId;

  const WallpaperLayout({
    super.key,
    this.wallpaperList,
    this.chatId,
    this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: wallpaperList!.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisSpacing: 20,
        mainAxisExtent: 216,
        mainAxisSpacing: 20.0,
        crossAxisCount: 2,
      ),
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: wallpaperList![index],
          imageBuilder: (context, imageProvider) => Container(
            width: MediaQuery.of(context).size.width,
            height: Sizes.s210,
            decoration: BoxDecoration(
              color: appCtrl.appTheme.screenBG,
              boxShadow: const [
                BoxShadow(
                    offset: Offset(0, 2),
                    blurRadius: 5,
                    spreadRadius: 1,
                    color: Color.fromRGBO(0, 0, 0, 0.08))
              ],
              borderRadius: BorderRadius.circular(AppRadius.r14),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(AppRadius.r10)),
              child: Image(image: imageProvider, fit: BoxFit.fill),
            ),
          ).inkWell(onTap: () async {
            log("Selected wallpaper for chatId: $chatId");

            /// Save wallpaper per chatId in GetStorage
            if(chatId != null) {
              appCtrl.storage.write('wallpaper_$chatId', wallpaperList![index]);
            }
            if(groupId != null) {
              appCtrl.storage.write('wallpaper_$groupId', wallpaperList![index]);
            }

            Get.back(result: wallpaperList![index]);
          }),
          errorWidget: (context, url, error) => Container(
            width: MediaQuery.of(context).size.width,
            height: Sizes.s210,
            decoration: BoxDecoration(
              color: appCtrl.appTheme.screenBG,
              boxShadow: const [
                BoxShadow(
                    offset: Offset(0, 2),
                    blurRadius: 5,
                    spreadRadius: 1,
                    color: Color.fromRGBO(0, 0, 0, 0.08))
              ],
              borderRadius: BorderRadius.circular(AppRadius.r14),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(AppRadius.r10)),
              child: Image.asset(eImageAssets.loginImage, fit: BoxFit.fill),
            ),
          ),
        );
      },
    );
  }
}
