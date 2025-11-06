import 'package:chatzy/config.dart';

class FullScreenGif extends StatefulWidget {
  final dynamic document;

  const FullScreenGif({super.key, required this.document});

  @override
  State<FullScreenGif> createState() => _FullScreenGifState();
}

class _FullScreenGifState extends State<FullScreenGif> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: appCtrl.appTheme.mainBg,
        body: Stack(
          children: [
            ClipRRect(
                borderRadius:
                    SmoothBorderRadius(cornerRadius: 15, cornerSmoothing: 1),
                child: Image.network(decryptMessage(widget.document)).center()),
            BackButton(
                color: appCtrl.appTheme.sameWhite,
                onPressed: () {
                  Get.back();
                }).paddingDirectional(top: Sizes.s50, horizontal: Sizes.s20)
          ],
        ));
  }
}
