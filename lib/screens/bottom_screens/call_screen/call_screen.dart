import 'dart:developer';

import 'package:chatzy/screens/bottom_screens/call_screen/layouts/call_view.dart';
import 'package:flutter/cupertino.dart';
import '../../../config.dart';

class CallScreen extends StatefulWidget {
  CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  final callListCtrl = Get.put(CallListController());
  final List<Tab> myTabs = <Tab>[
    const Tab(text: 'Пропущенные'),
    const Tab(text: 'Другие'),
  ];

  TabController? tabController;

  @override
  void initState() {
    super.initState();
    tabController = new TabController(vsync: this, length: myTabs.length);
  }

  @override
  Widget build(BuildContext context) {

    return PickupLayout(
      scaffold: GetBuilder<CallListController>(builder: (_) {
        return GetBuilder<DashboardController>(builder: (dashCtrl) {
          return Scaffold(
              backgroundColor: appCtrl.isTheme
                  ? appCtrl.appTheme.screenBG
                  : appCtrl.appTheme.white,
              appBar: AppBar(
                  toolbarHeight: Sizes.s70,
                  backgroundColor: appCtrl.isTheme
                      ? appCtrl.appTheme.screenBG
                      : appCtrl.appTheme.white,
                  elevation: 0,
                  actions: [
                    /*              if (!callListCtrl.isSearch)
                      ActionIconsCommon(
                          icon: eSvgAssets.search,
                          vPadding: Insets.i15,
                          onTap: () {
                            callListCtrl.isSearch = true;
                            callListCtrl.update();
                          },
                          color: appCtrl.appTheme.white),*/
                    if (!callListCtrl.isSearch) const HSpace(Sizes.s15),
                    if (!callListCtrl.isSearch)
                      ActionIconsCommon(
                          icon: eSvgAssets.trash,
                          vPadding: Insets.i15,
                          onTap: () => callListCtrl.buildPopupDialog(),
                          color: appCtrl.appTheme.white),
                    const HSpace(Sizes.s20),
                  ],
                  bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(4.0),
                      child: Container(
                          color: const Color.fromRGBO(127, 131, 132, 0.15),
                          height: 2,
                          margin: const EdgeInsets.symmetric(
                              horizontal: Insets.i20))),
                  title: callListCtrl.isSearch
                      ? SizedBox(
                    height: Sizes.s50,
                    child: TextFieldCommon(
                        controller: callListCtrl.searchText,
                        hintText: "Search...",
                        fillColor: appCtrl.appTheme.white,
                        autoFocus: true,
                        border: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: appCtrl.appTheme.darkText
                            ),
                            borderRadius:
                            BorderRadius.circular(AppRadius.r8)),
                        keyboardType: TextInputType.multiline,
                        onChanged: (val) {
                          log("hello search");
                          callListCtrl.onSearch(val);
                          callListCtrl.update();
                        },
                        suffixIcon:
                        callListCtrl.searchText.text.isNotEmpty
                            ? Icon(CupertinoIcons.multiply,
                            color: appCtrl.appTheme.white,
                            size: Sizes.s15)
                            .decorated(
                            color: appCtrl.appTheme.darkText
                                .withOpacity(.3),
                            shape: BoxShape.circle)
                            .marginAll(Insets.i12)
                            .inkWell(onTap: () {
                          callListCtrl.isSearch = false;
                          callListCtrl.searchText.text = "";
                          callListCtrl.update();
                        })
                            : SvgPicture.asset(eSvgAssets.search,
                            height: Sizes.s15)
                            .marginAll(Insets.i12)
                            .inkWell(onTap: () {
                          callListCtrl.isSearch = false;
                          callListCtrl.searchText.text = "";
                          callListCtrl.update();
                        })),
                  )
                      : Text(appFonts.Z.tr,
                      style: AppCss.muktaVaani20
                          .textColor(appCtrl.appTheme.darkText))),
              body: RefreshIndicator(
                onRefresh: ()async{
                  callListCtrl.getAllCallList();
                },
                child: Column(children: [
                  TabBar(
                    controller: tabController,
                    tabs: myTabs,
                    labelColor: appCtrl.appTheme.primary,
                    labelStyle: AppCss.manropeSemiBold12
                        .textColor(appCtrl.appTheme.primary),
                    unselectedLabelColor: appCtrl.appTheme.greyText,
                    unselectedLabelStyle: AppCss.manropeSemiBold12
                        .textColor(appCtrl.appTheme.greyText),
                    isScrollable: false,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: materialIndicator(),
                  ),
                  Expanded(
                      child: TabBarView(controller: tabController, children: [
                        // Tab 1: Missed Calls
                        callListCtrl.inComing.isEmpty?Center(
                            child: Text('Нет пропущенных звонков',
                                style: TextStyle(
                                    color: appCtrl.appTheme.darkText))):  RefreshIndicator(
                          onRefresh: () async{
                            callListCtrl.getAllCallList();
                          },
                          child: ListView.builder(
                              itemCount: callListCtrl.inComing.length,
                              itemBuilder: (context, index) {

                                QueryDocumentSnapshot<Object?> call = callListCtrl.inComing[index];
                                bool isMissCallSelected = callListCtrl
                                    .isMissCallSelected(call.exists
                                    ? call.id
                                    : callListCtrl.results[index]
                                    .id); // Check if item is selected
                                bool clearMissCallSelection =
                                callListCtrl.isMissCallSelectionActive();
                                return GestureDetector(
                                    onLongPress: () {
                                      log("Long press detected at index $index");
                                      if (!clearMissCallSelection) {
                                        callListCtrl.clearMissCallSelection();
                                      }
                                      callListCtrl.toggleMissCallSelection(
                                          call.exists
                                              ? call.id
                                              : callListCtrl.results[index].id);
                                    },
                                    onTap: () {
                                      log("Tap detected at index $index");
                                      if (isMissCallSelected) {
                                        callListCtrl.toggleMissCallSelection(
                                            call.exists
                                                ? call.id
                                                : callListCtrl.results[index].id);
                                      }
                                    },
                                    child: Stack(children: [
                                      CallView(
                                          snapshot: call.data(),
                                          index: index,
                                          userId: appCtrl.user["id"]),
                                      Container(
                                          height: Sizes.s80,
                                          width: double.infinity,
                                          color: isMissCallSelected
                                              ? appCtrl.appTheme.primaryShadow
                                              : appCtrl.appTheme.trans)
                                          .paddingDirectional(top: Sizes.s2)
                                    ]));
                              }),
                        ),
                        // Tab 2: Other Calls
                        RefreshIndicator(
                          onRefresh: () async{
                            callListCtrl.getAllCallList();
                          },
                          child: ListView.builder(
                              itemCount: callListCtrl.callingList.length,
                              itemBuilder: (context, index) {
                                QueryDocumentSnapshot<Object?> callData = callListCtrl.callingList[index];
                                log("callData:${callData.data()}");
                                bool isSelected = callListCtrl.isSelected(
                                    callData.exists
                                        ? callData.id
                                        : callListCtrl.results[index]
                                        .id); // Check if item is selected
                                bool isSelectionActive =
                                callListCtrl.isSelectionActive();
                                return GestureDetector(
                                    onLongPress: () {
                                      log("Long press detected at index $index");
                                      if (!isSelectionActive) {
                                        callListCtrl.clearSelection();
                                      }
                                      callListCtrl.toggleSelection(
                                          callData.exists
                                              ? callData.id
                                              : callListCtrl.results[index].id);
                                    },
                                    onTap: () {
                                      log("Tap detected at index $index");

                                      if (isSelectionActive) {
                                        callListCtrl.toggleSelection(
                                            callData.exists
                                                ? callData.id
                                                : callListCtrl.results[index].id);
                                      }
                                    },
                                    child: Stack(children: [
                                      CallView(
                                          snapshot: callData.data(),
                                          index: index,
                                          userId: appCtrl.user["id"]
                                      ),
                                      Container(
                                          height: Sizes.s80,
                                          width: double.infinity,
                                          color: isSelected
                                              ? appCtrl.appTheme.primaryShadow
                                              : appCtrl.appTheme.trans)
                                          .paddingDirectional(top: Sizes.s2)
                                    ]));
                              }),
                        )

                      ]))
                ]),
              ));

        });
      }),
    );
  }
}
