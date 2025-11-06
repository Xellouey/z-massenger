import 'dart:developer';
import '../../../../config.dart';

class CallView extends StatefulWidget {
  final dynamic snapshot;
  final int? index;
  final String? userId;
  final bool? isSelected;

  const CallView(
      {super.key, this.snapshot, this.index, this.userId, this.isSelected});

  @override
  State<CallView> createState() => _CallViewState();
}

class _CallViewState extends State<CallView> {
  int? indexVal;
  String? chatId;
  UserContactModel? userContact;
  Stream? callStream;

  @override
  void initState() {
    // TODO: implement initState
    fetch();
    callStream = FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(widget.snapshot["id"] == appCtrl.user["id"]
        ? widget.snapshot["receiverId"]
        : widget.snapshot["id"])
        .snapshots();
    super.initState();
  }

  fetch() async {
    await FirebaseFirestore.instance
        .collection(collectionName.users)
        .doc(widget.snapshot["id"] == appCtrl.user["id"]
        ? widget.snapshot["receiverId"]
        : widget.snapshot["id"])
        .get()
        .then((e) async {
      if (e.exists) {
        await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(appCtrl.user['id'])
            .collection(collectionName.chats)
            .where("isOneToOne", isEqualTo: true)
            .get()
            .then((value) {
          if (value.docs.isNotEmpty) {
            // log("VAL :${value.docs[0].data()}");
            indexVal = value.docs.indexWhere((element) =>
            element.data().isNotEmpty &&
                (element.data()['receiverId'] ==
                    widget.snapshot["receiverId"] ||
                    element.data()['senderId'] ==
                        widget.snapshot["receiverId"]) ||
                element.data()['receiverId'] == widget.snapshot["id"] ||
                element.data()['senderId'] == widget.snapshot["id"]);
            if (indexVal! >= 0) {
              // log("dsfgh :${value.docs[indexVal!].data()}");
              userContact = UserContactModel(
                  username: e.data()!["name"],
                  uid: widget.snapshot["receiverId"],
                  phoneNumber: e.data()!["phone"],
                  image: e.data()!["image"],
                  isRegister: true);
              chatId = value.docs[indexVal!].data()['chatId'];
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CallListController>(builder: (callList) {
      return Stack(
        children: [
          SvgPicture.asset(eSvgAssets.pin).padding(
              horizontal: appCtrl.isRTL || appCtrl.languageVal == "ar"
                  ? MediaQuery.of(context).size.width / 6
                  : MediaQuery.of(context).size.width / 5.8,
              top: MediaQuery.of(context).size.height / 35),
          Column(children: [
            Row(
              children: [
                ImageLayout(
                    isLastSeen: false,
                    id: widget.snapshot["id"] == appCtrl.user["id"]
                        ? widget.snapshot["receiverId"]
                        : widget.snapshot["id"]),
                const HSpace(Sizes.s12),
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(Insets.i15),
                    decoration: BoxDecoration(
                        color: appCtrl.appTheme.white,
                        boxShadow: [
                          BoxShadow(
                              color:
                              appCtrl.appTheme.borderColor.withOpacity(0.5),
                              blurRadius: AppRadius.r5,
                              spreadRadius: AppRadius.r2)
                        ],
                        border: Border.all(
                            color: const Color.fromRGBO(127, 131, 132, 0.15),
                            width: 1.2),
                        borderRadius: BorderRadius.circular(AppRadius.r8)),
                    child: StreamBuilder(
                        stream: callStream,
                        builder: (context, snapShot) {
                          if (snapShot.hasData && snapShot.data != null) {
                            return Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                          width: Sizes.s180,
                                          child: Text(
                                              snapShot.data != null &&
                                                  snapShot.data != null
                                                  ? snapShot.data!['name'] ?? "test"
                                                  : "Anonymous",
                                              overflow: TextOverflow.clip,
                                              style: AppCss.manropeSemiBold14
                                                  .textColor(appCtrl
                                                  .appTheme.darkText))),
                                      const VSpace(Sizes.s5),
                                      CallIcon(
                                          snapshot: widget.snapshot,
                                          index: widget.index),
                                    ],
                                  ),
                                  SvgPicture.asset(
                                      widget.snapshot["isVideoCall"]
                                          ? eSvgAssets.video
                                          : eSvgAssets.callOut,
                                      colorFilter: ColorFilter.mode(
                                          widget.snapshot['type'].toString().toLowerCase() ==
                                              'inComing'.toLowerCase()
                                              ? (widget.snapshot[
                                          'started'] ==
                                              null
                                              ? widget.snapshot[
                                          'receiverId'] ==
                                              appCtrl.user["id"]
                                              ? appCtrl
                                              .appTheme.redColor
                                              : appCtrl
                                              .appTheme.primary
                                              : appCtrl
                                              .appTheme.primary)
                                              : (widget.snapshot[
                                          'started'] ==
                                              null
                                              ? widget.snapshot[
                                          'receiverId'] ==
                                              appCtrl.user["id"]
                                              ? appCtrl
                                              .appTheme.redColor
                                              : appCtrl
                                              .appTheme.primary
                                              : appCtrl
                                              .appTheme.primary),
                                          BlendMode.srcIn))
                                      .inkWell(onTap: () async {
                                    // await ChatMessageApi().audioAndVideoCallApi(
                                    //     toData:
                                    //         widget.snapshot,
                                    //     isVideoCall: widget.snapshot!.data!.docs[widget.index!]
                                    //         .data()["isVideoCall"]);
                                  })
                                ]);
                          } else {
                            return Container();

                          }
                        }),
                  ),
                )
              ],
            ).marginSymmetric(vertical: Insets.i10)
          ]).marginSymmetric(horizontal: Insets.i20),
        ],
      );
    });
  }
}
