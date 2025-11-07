
import 'package:flutter/cupertino.dart';

import '../../../config.dart';

class InvitePeopleScreen extends StatefulWidget {


  const InvitePeopleScreen({super.key});

  @override
  State<InvitePeopleScreen> createState() => _InvitePeopleScreenState();
}

class _InvitePeopleScreenState extends State<InvitePeopleScreen> {
  @override
  void initState() {

    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InvitePeopleController>(
        init: InvitePeopleController(),
        builder: (controller) {
      return Scaffold(
          backgroundColor: appCtrl.appTheme.screenBG,
          appBar: AppBar(
              centerTitle: true,
              title: Text(appFonts.invitePeople.tr,
                  style: AppCss.manropeBold16
                      .textColor(appCtrl.appTheme.darkText)),
              backgroundColor: appCtrl.appTheme.screenBG,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                Text(appFonts.skip.tr,
                        style: AppCss.manropeBold14
                            .textColor(appCtrl.appTheme.greyText))
                    .inkWell(onTap: controller.onSkip)
                    .alignment(Alignment.center)
                    .paddingSymmetric(horizontal: Insets.i20)
              ]),
          body: Padding(
            padding: const EdgeInsets.all(Insets.i20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(Insets.i30),
                  decoration: BoxDecoration(
                    color: appCtrl.appTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.person_add_solid,
                    size: Sizes.s80,
                    color: appCtrl.appTheme.primary,
                  ),
                ),
                const VSpace(Sizes.s30),
                // Title
                Text(
                  appFonts.invitePeople.tr,
                  style: AppCss.manropeBold20
                      .textColor(appCtrl.appTheme.darkText),
                  textAlign: TextAlign.center,
                ),
                const VSpace(Sizes.s15),
                // Description
                Text(
                  "Поделитесь Z Messenger с друзьями и начните общаться вместе!",
                  style: AppCss.manropeMedium14
                      .textColor(appCtrl.appTheme.greyText),
                  textAlign: TextAlign.center,
                ),
                const VSpace(Sizes.s40),
                // Invite button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: appCtrl.appTheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => controller.onInvitePeople(),
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: Insets.i15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.share,
                              color: appCtrl.appTheme.sameWhite,
                              size: Sizes.s20,
                            ),
                            const HSpace(Sizes.s10),
                            Text(
                              "Пригласить друзей",
                              style: AppCss.manropeSemiBold16
                                  .textColor(appCtrl.appTheme.sameWhite),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const VSpace(Sizes.s15),
                // Skip info
                Text(
                  "Вы можете пропустить этот шаг и пригласить друзей позже",
                  style: AppCss.manropeMedium12
                      .textColor(appCtrl.appTheme.greyText),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ));
    });
  }
}
