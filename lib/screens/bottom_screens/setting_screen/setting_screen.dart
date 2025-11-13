import '../../../config.dart';
import '../../../controllers/bottom_controllers/setting_controller.dart';
import 'layouts/setting_layout.dart';

class SettingScreen extends StatelessWidget {
  final settingCtrl = Get.put(SettingController());

  SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PickupLayout(scaffold: GetBuilder<SettingController>(builder: (_) {
      return DirectionalityRtl(
          child: GetBuilder<DashboardController>(builder: (dashCtrl) {
        return Scaffold(
            backgroundColor: appCtrl.appTheme.screenBG,
            appBar: AppBar(
                backgroundColor: appCtrl.appTheme.screenBG,
                elevation: 0,
                centerTitle: true,
                automaticallyImplyLeading: false,
                title: Text(appFonts.setting.tr,
                    style: AppCss.muktaVaani20
                        .textColor(appCtrl.appTheme.darkText))),
            body: ListView(
                    children: settingCtrl.settingLists
                        .asMap()
                        .entries
                        .map((e) => e.value['title'] == appFonts.logOut
                            ? !appCtrl.usageControlsVal!.showLogoutButton!
                                ? Container()
                                : SettingLayout(
                                    val: e.value,
                                    index: e.key,
                                    onChanged: (value) =>
                                        settingCtrl.onChange(value, e.value),
                                    value: e.value['title'] == appFonts.fingerLock
                                            ? appCtrl.isBiometric
                                            : appCtrl.isTheme,
                                    onTap: () =>
                                        settingCtrl.onSettingTap(e.value))
                            : SettingLayout(
                                val: e.value,
                                index: e.key,
                                onChanged: (value) =>
                                    settingCtrl.onChange(value, e.value),
                                value: e.value['title'] == appFonts.fingerLock
                                        ? appCtrl.isBiometric
                                        : appCtrl.isTheme,
                                onTap: () => settingCtrl.onSettingTap(e.value)))
                        .toList())
                .paddingAll(Insets.i20));
      }));
    }));
  }
}
