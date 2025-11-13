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
            Image.asset(
              eImageAssets.icLauncherPlaystore,
              height: 150,
              width: 150,
            ),
          ],
        ),
      );
    });
  }
}
