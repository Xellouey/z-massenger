import 'dart:developer';

import 'package:chatzy/screens/bottom_screens/call_screen/layouts/call_view.dart';

import '../../../../config.dart';

class CallListLayout extends StatelessWidget {
  final AsyncSnapshot? snapshot;
  final List<DocumentSnapshot>? results;
  const CallListLayout({
    super.key,
    this.snapshot,
    this.results,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CallListController>(builder: (callListCtrl) {
      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: Insets.i10),
        itemBuilder: (context, index) {
          bool isSelected = callListCtrl.isSelected(snapshot != null
              ? snapshot!.data!.docs[index].id
              : results![index].id); // Check if item is selected
          bool isSelectionActive = callListCtrl
              .isSelectionActive(); // Check if any items are selected
          return GestureDetector(
              onLongPress: () {
                log("Long press detected at index $index");
                if (!isSelectionActive) {
                  callListCtrl.clearSelection();
                }
                callListCtrl.toggleSelection(snapshot != null
                    ? snapshot!.data!.docs[index].id
                    : results![index].id);
              },
              onTap: () {
                log("Tap detected at index $index");
                // Deselect the item if it is already selected
                if (isSelected != 1) {
                  callListCtrl.toggleSelection(snapshot != null
                      ? snapshot!.data!.docs[index].id
                      : results![index].id);
                }
              },
              child: Stack(children: [
                CallView(
                    snapshot: snapshot != null
                        ? snapshot!.data!.docs[index].data()
                        : results![index].data(),
                    index: index,
                    userId: appCtrl.user["id"]),
                Container(
                    height: Sizes.s80,
                    width: double.infinity,
                    color: isSelected
                        ? appCtrl.appTheme.primaryShadow
                        : appCtrl.appTheme.trans)
                    .paddingDirectional(top: Sizes.s2)
              ]));
        },
        itemCount:
        snapshot != null ? snapshot!.data!.docs.length : results!.length,
      );
    });
  }
}
