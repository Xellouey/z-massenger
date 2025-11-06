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
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: Insets.i20),
              child: Text(
                  appCtrl.user != null
                      ? "Добро пожаловать, ${appCtrl.user['name']}"
                      : "Добро пожаловать",
                  style:
                      AppCss.muktaVaani40.textColor(Colors.black)),
            ),
          ));
    });
  }
}
