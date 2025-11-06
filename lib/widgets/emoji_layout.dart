import '../config.dart';

class EmojiLayout extends StatelessWidget {
  final String? emoji;
  final GestureTapCallback? onTap;
  const EmojiLayout({super.key,this.emoji,this.onTap});


  @override
  Widget build(BuildContext context) {
    return Text(emoji!,style: AppCss.manropeBold10)
        .paddingAll(Insets.i5)
        .decorated(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: appCtrl.appTheme.borderColor,
              blurRadius: 2,spreadRadius: 2
          )
        ],
        color: appCtrl.appTheme.white).paddingSymmetric(horizontal: Insets.i15).inkWell(onTap:onTap);
  }
}
