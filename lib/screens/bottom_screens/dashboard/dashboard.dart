import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../../config.dart';
import '../../../controllers/recent_chat_controller.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final dashboardCtrl = Get.put(DashboardController());
  final statusCtrl = Get.isRegistered<StatusController>()
      ? Get.find<StatusController>()
      : Get.put(StatusController());

  @override
  void initState() {
    // TODO: implement initState
    dashboardCtrl.prefs = Get.arguments;
    WidgetsBinding.instance.addObserver(this);
    dashboardCtrl.initConnectivity();
    setState(() {});
    statusCtrl.getAllStatus();
    setState(() {});
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    log("state ; $state");
    if (state == AppLifecycleState.resumed) {
      firebaseCtrl.setIsActive();
      dashboardCtrl.update();
      Get.forceAppUpdate();
    } else {
      firebaseCtrl.setLastSeen();
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {}
    firebaseCtrl.statusDeleteAfter24Hours();
    // firebaseCtrl.deleteForAllUsers();

    firebaseCtrl.syncContact();
  }

  @override
  Widget build(BuildContext context) {
    log("FCM : ${appCtrl.user['pushToken']}");

    return PickupLayout(scaffold:
        Consumer<RecentChatController>(builder: (context, recentChat, child) {
      return GetBuilder<DashboardController>(builder: (_) {
        // log("message::${appCtrl.user['id']}");
        return DirectionalityRtl(
            child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  log("result :$didPop");
                  if (didPop) return;
                  log("dashboardCtrl.isLongPress:${dashboardCtrl.isLongPress}");
                  if (dashboardCtrl.isSearch == true) {
                    dashboardCtrl.isSearch = false;
                    dashboardCtrl.searchText.text = "";
                    dashboardCtrl.update();
                  } else if (dashboardCtrl.isLongPress) {
                    dashboardCtrl.isLongPress = false;
                    dashboardCtrl.selectedChat = [];
                    dashboardCtrl.update();
                  } else if (dashboardCtrl.tabController!.index != 0) {
                    dashboardCtrl.onChange(0);
                    dashboardCtrl.tabController!.index = 0;
                    dashboardCtrl.update();
                  } else {
                    if (dashboardCtrl.backCounter == 0) {
                      Fluttertoast.showToast(msg: "Back Press Again");
                      log("dashboardCtrl.${dashboardCtrl.backCounter}");
                      dashboardCtrl.backCounter++;
                      dashboardCtrl.update();
                    } else {
                      log("dghfdjhg");
                      dashboardCtrl.backCounter = 0;
                      dashboardCtrl.update();
                      SystemNavigator.pop();
                    }
                  }
                },
                child: Scaffold(
                    backgroundColor: appCtrl.appTheme.screenBG,
                    body: dashboardCtrl.bottomNavLists.isEmpty
                        ? Container()
                        : DefaultTabController(
                            length: dashboardCtrl.bottomNavLists.length,
                            initialIndex: 0,
                            child: Stack(children: [
                              Scaffold(
                                  floatingActionButton: dashboardCtrl
                                                  .tabController?.index ==
                                              0 ||
                                          dashboardCtrl.tabController?.index ==
                                              1
                                      ? FloatingActionButton(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(50)),
                                          backgroundColor:
                                              appCtrl.appTheme.primary,
                                          onPressed: () =>
                                              dashboardCtrl.onTapActionButton(),
                                          child: SvgPicture.asset(
                                              dashboardCtrl.tabController?.index == 0
                                                  ? eSvgAssets.message
                                                  : eSvgAssets.mobile))
                                      : Container(),
                                  bottomNavigationBar: SizedBox(
                                          height: Sizes.s70,
                                          child: TabBar(
                                              onTap: (val) {
                                                dashboardCtrl
                                                    .tabController?.index = val;
                                                dashboardCtrl.update();
                                              },
                                              controller:
                                                  dashboardCtrl.tabController,
                                              labelColor:
                                                  appCtrl.appTheme.primary,
                                              labelStyle: AppCss.manropeSemiBold12
                                                  .textColor(appCtrl.appTheme.primary),
                                              unselectedLabelColor: appCtrl.appTheme.greyText,
                                              unselectedLabelStyle: AppCss.manropeSemiBold12.textColor(appCtrl.appTheme.greyText),
                                              isScrollable: false,
                                              indicatorSize: TabBarIndicatorSize.tab,
                                              indicator: materialIndicator(),
                                              tabs: dashboardCtrl.bottomNavLists.asMap().entries.map((e) {
                                                return Tab(
                                                    icon: e.key == 3
                                                        ? SizedBox(height: Sizes.s25, width: Sizes.s25, child: ClipRRect(borderRadius: const BorderRadius.all(Radius.circular(AppRadius.r20)), child: dashboardCtrl.data != "" ? Image.network(dashboardCtrl.data!, fit: BoxFit.cover) : Text(appCtrl.user['name'].replaceAll(" ", "").substring(0, 2).toUpperCase() ?? "", style: AppCss.manropeMedium14.textColor(appCtrl.appTheme.primaryLight2)).alignment(Alignment.center).paddingOnly(top: 2)))
                                                            .paddingAll(
                                                                Insets.i1)
                                                            .decorated(
                                                                color: appCtrl
                                                                    .appTheme
                                                                    .primary,
                                                                shape: BoxShape
                                                                    .circle)
                                                        : SvgPicture.asset(dashboardCtrl
                                                                    .tabController
                                                                    ?.index ==
                                                                e.key
                                                            ? e.value["icon"]
                                                            : e.value["icon2"]),
                                                    text: e.value["title"]
                                                        .toString()
                                                        .tr);
                                              }).toList()))
                                      .decorated(color: appCtrl.appTheme.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppRadius.r8), topRight: Radius.circular(AppRadius.r8)))
                                      .paddingOnly(top: Insets.i1)
                                      .bottomNavDecoration(),
                                  body: TabBarView(controller: dashboardCtrl.tabController, children: dashboardCtrl.pages)),
                              if (appCtrl.isLoading)
                                Container(
                                    color: Colors.black26.withOpacity(.4),
                                    child: Center(
                                        child: Material(
                                            elevation: 3,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(60)),
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                        Color>(
                                                                    appCtrl
                                                                        .appTheme
                                                                        .primary),
                                                            // appColor.primaryColor
                                                            strokeWidth: 3))))))
                            ])))));
      });
    }));
  }
}
