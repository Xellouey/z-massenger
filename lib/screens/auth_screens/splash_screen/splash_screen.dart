import 'dart:developer';

import '../../../config.dart';

class SplashScreen extends StatelessWidget {
  final SharedPreferences? pref;
  final DocumentSnapshot<Map<String, dynamic>> rm, uc;
  final splashCtrl = Get.put(SplashController());

  SplashScreen({super.key, this.pref, required this.rm, required this.uc});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(builder: (_) {
      splashCtrl.pref = pref;
      splashCtrl.rmk = rm;
      splashCtrl.uck = uc;
      splashCtrl.update();
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  eImageAssets.appLogo,
                  height: 100,
                  width: 100,
                ),
                const VSpace(Sizes.s20),
                Text(
                  appFonts.Z.tr,
                  style: AppCss.muktaVaani40.textColor(Colors.white),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
