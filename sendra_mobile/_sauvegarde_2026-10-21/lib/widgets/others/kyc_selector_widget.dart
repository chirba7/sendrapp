import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/labels/text_labels_widget.dart';

class KycSelectorWidget extends StatefulWidget {
  const KycSelectorWidget({Key? key}) : super(key: key);

  @override
  State<KycSelectorWidget> createState() => _KycSelectorWidgetState();
}

class _KycSelectorWidgetState extends State<KycSelectorWidget> {
  int selectedIndex = 0;
  int cardSelectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return _optionWidget(context);
  }



  Container _optionWidget(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(Dimensions.marginSize),
      child: Column(
        children: [
          TextLabelsWidget(
            textLabels: Strings.chooseOne,
            textColor: CustomColor.textColor,
          ),
          Row(
            mainAxisAlignment: mainSpaceBet,
            children: [
              _options(context, FontAwesomeIcons.solidIdCard, Strings.nidCard, 0),
              _options(context, FontAwesomeIcons.passport, Strings.passport, 1),
              _options(context, FontAwesomeIcons.solidIdCard,
                  Strings.drivingLicense, 2),
            ],
          ),
        ],
      ),
    );
  }



  GestureDetector _options(BuildContext context, IconData icon, String name, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        alignment: Alignment.topCenter,
        padding: EdgeInsets.all(Dimensions.defaultPaddingSize * 0.5),
        child: Column(
          mainAxisAlignment: mainStart,
          crossAxisAlignment: crossCenter,
          children: [
            Container(
              // height: 70,
              // width: ,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: selectedIndex == index
                    ? CustomColor.primaryColor
                    : CustomColor.gray,
                size: 40,
              ),
            ),
            Container(
              width: 70,
              padding: EdgeInsets.symmetric(vertical: Dimensions.defaultPaddingSize * 0.2),
              child: Text(
                name,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: CustomStyler.otpVerificationDescriptionStyle,
              ),
            )
          ],
        ),
      ),
    );
  }
}
