import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import '../../widgets/others/back_button_widget.dart';

class RequestMoneyReviewScreen extends StatelessWidget {
  const RequestMoneyReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.requestMoneyPreview,
          style: TextStyle(color: CustomColor.whiteColor),
        ),
        leading: const BackButtonWidget(
          backButtonImage: Strings.backButtonWhite,
        ),
        backgroundColor: CustomColor.primaryColor,
        elevation: 0,
      ),
      body: _bodyWidget(context),
    );
  }

  ListView _bodyWidget(BuildContext context) {
    return ListView(
      children: [
        _detailsWidget(context),
        _requestMoneyButtonWidget(context),
      ],
    );
  }

  Container _detailsWidget(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(Dimensions.marginSize * 0.5),
      child: Column(
        mainAxisAlignment: mainStart,
        crossAxisAlignment: crossStart,
        children: [
          Text(
            Strings.confirmDetails,
            style: CustomStyler.onboardTitleStyle,
          ),
          const Divider(),
          _rowWidget(context, Strings.name, Strings.userName),
          const Divider(),
          _rowWidget(context, Strings.email, Strings.userEmail),
          const Divider(),
          _rowWidget(context, Strings.country, Strings.userCountry),
          const Divider(),
          _rowWidget(context, Strings.paymentDueBy, Strings.paymentDueByDate),
          const Divider(),
          _rowUsdWidget(context, Strings.requestMoney, Strings.requestedAmount),
          const Divider(),
          _rowWidget(context, Strings.description, Strings.descriptionAll),
        ],
      ),
    );
  }

  PrimaryButtonWidget _requestMoneyButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: Strings.requestMoney,
      onPressed: () {
        Get.toNamed(Routes.requestMoneySuccessScreen);
      },
      borderColor: CustomColor.primaryColor,
      backgroundColor: CustomColor.primaryColor,
      textColor: CustomColor.whiteColor,
    );
  }

  Row _rowWidget(BuildContext context, String title, String amount) {
    return Row(
      mainAxisAlignment: mainSpaceBet,
      children: [
        Text(
          title,
          textAlign: TextAlign.justify,
          style: CustomStyler.otpVerificationDescriptionStyle,
        ),
        Row(
          children: [
            Text(
              amount,
              textAlign: TextAlign.right,
              style: CustomStyler.otpVerificationDescriptionStyle,
            ),
          ],
        )
      ],
    );
  }

  Row _rowUsdWidget(BuildContext context, String title, String amount) {
    return Row(
      mainAxisAlignment: mainSpaceBet,
      children: [
        Text(
          title,
          style: CustomStyler.otpVerificationDescriptionStyle,
        ),
        Row(
          children: [
            Text(
              amount,
              style: CustomStyler.otpVerificationDescriptionStyle,
            ),
            addHorizontalSpace(5.w),
            Text(
              Strings.usd,
              style: CustomStyler.otpVerificationDescriptionStyle,
            ),
          ],
        )
      ],
    );
  }
}
