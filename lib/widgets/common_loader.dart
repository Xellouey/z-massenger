import '../../../../config.dart';


class CommonLoader extends StatelessWidget {

  const CommonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (appCtrl) {
        return  Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: appCtrl.isTheme?Colors.black.withOpacity(.3) : const Color(0xFF00162E).withOpacity(0.2),
            child: Center(
                child:CircularProgressIndicator( valueColor:
                AlwaysStoppedAnimation<
                    Color>(
                    appCtrl.appTheme
                        .primary),

                    strokeWidth: 3)
            )
        );
          /*Center(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<
                        Color>(
                        appCtrl.appTheme
                            .primary),

                    strokeWidth: 3)))*/;
      }
    );
  }
}
