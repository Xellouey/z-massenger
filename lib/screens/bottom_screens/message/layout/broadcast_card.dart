import 'package:intl/intl.dart';
import '../../../../config.dart';

class BroadCastMessageCard extends StatelessWidget {
  final DocumentSnapshot? document;
  final String? currentUserId;
  final GestureLongPressCallback? onLongPress;
  final bool isAvailable, isLongPress;
  final GestureTapCallback? onTap;

  const BroadCastMessageCard({super.key, this.document, this.currentUserId, this.onLongPress,
    this.isAvailable = false,
    this.isLongPress = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    String nameList = "";
    List selectedContact = document!["receiverId"];
    selectedContact.asMap().forEach((key, value) {
      if (nameList != "") {
        nameList = "$nameList, ${value["name"]}";
      } else {
        nameList = value["name"];
      }
    });
    return Column(children: [
      Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Row(children: [
              if (isLongPress)
                Container(
                  height: Sizes.s20,width: Sizes.s20,
                  decoration: ShapeDecoration(
                      color: isAvailable
                          ? appCtrl.appTheme.primary
                          : appCtrl.appTheme.white,
                      shape:SmoothRectangleBorder(
                          side: BorderSide(
                              color: isAvailable? appCtrl.appTheme.primary: appCtrl.appTheme.greyText.withOpacity(.15)
                          ),
                          borderRadius: SmoothBorderRadius(
                              cornerRadius: 4,cornerSmoothing: 1
                          )
                      ) ),
                  child: isAvailable? SvgPicture.asset(eSvgAssets.tick1):null,
                ).inkWell(onTap: onTap),
              if (isLongPress)
                const HSpace(25),
              Container(
                  height: Sizes.s45,
                  width: Sizes.s45,
                  decoration: BoxDecoration(
                      color: appCtrl.appTheme.primaryLight,
                      shape: BoxShape.circle),
                  child: SvgPicture.asset(eSvgAssets.broadCast,
                      height: Sizes.s25,
                      width: Sizes.s25,
                      fit: BoxFit.scaleDown,
                      colorFilter: ColorFilter.mode(
                          appCtrl.appTheme.primary, BlendMode.srcIn))),
              const HSpace(Sizes.s12),
              SizedBox(
                  width: Sizes.s150,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            /*document!["name"] != "Broadcast" && document!["name"] != "" ?*/
                            document!["name"] ?? nameList /*: nameList*/,
                            overflow: TextOverflow.ellipsis,
                            style: AppCss.manropeblack14
                                .textColor(appCtrl.appTheme.black)),
                        const VSpace(Sizes.s5),
                        Text(
                            document!["lastMessage"] != ""
                                ? decryptMessage(document!["lastMessage"])
                                : "",
                            overflow: TextOverflow.ellipsis,
                            style: AppCss.manropeMedium14
                                .textColor(appCtrl.appTheme.darkText))
                      ]))
            ]),
            Text(
                    DateFormat('HH:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(
                            int.parse(document!['updateStamp']))),
                    style: AppCss.manropeMedium12
                        .textColor(appCtrl.appTheme.darkText))
                .paddingOnly(top: Insets.i8)
          ])
          .paddingSymmetric(horizontal: Insets.i10, vertical: Insets.i15)
          .inkWell(onTap: () {
        var data = {
          "broadcastId": document!["broadcastId"],
          "data": document!.data(),
        };
        Get.toNamed(routeName.broadcastChat, arguments: data);
      }),
      Divider(height: 1, thickness: 1, color: appCtrl.appTheme.borderColor)
          .paddingSymmetric(horizontal: Insets.i10)
    ]).inkWell(onLongPress: onLongPress);
  }
}
