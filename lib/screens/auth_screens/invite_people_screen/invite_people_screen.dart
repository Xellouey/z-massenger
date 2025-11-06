
import 'package:chatzy/controllers/common_controllers/contact_controller.dart';
import 'package:chatzy/widgets/common_loader.dart';

import '../../../config.dart';
import 'layouts/un_register_user.dart';

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
          body: Consumer<ContactProvider>(
              builder: (context, availableContacts, child) {
            final unregistered = availableContacts.invitedContacts;

            if (availableContacts.isLoading && unregistered.isEmpty) {
              return const CommonLoader();
            }

            return RefreshIndicator(
                onRefresh: () async {
                  return availableContacts
                      .fetchContacts(appCtrl.user["phone"]);
                },
                child: unregistered.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height / 2,
                              child: Center(
                                  child: Text(appFonts.contactDataNotAvailable.tr,
                                      style: AppCss.manropeMedium14.textColor(
                                          appCtrl.appTheme.greyText))))
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Insets.i20, vertical: Insets.i20),
                        itemCount: unregistered.length,
                        itemBuilder: (context, idx) {
                          final unregister = unregistered[idx];
                          return UnRegisterUser(
                            image: availableContacts
                                .getInitials(unregister.name),
                            name: unregister.name,
                            onTap: () => controller.onInvitePeople(
                                number: unregister.phone),
                          );
                        }));
          }));
    });
  }
}
