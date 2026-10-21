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

class WithdrawMoneyPreviewScreen extends StatelessWidget {
  const WithdrawMoneyPreviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.withdrawMoneyReview,
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
        _depositButtonWidget(context),
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
          _rowWidget(context, Strings.accountHolderName, Strings.userName),
          const Divider(),
          _rowWidget(context, Strings.accountNumber, Strings.userAccountNumber),
          const Divider(),
          _rowWidget(context, Strings.country, Strings.userCountry),
          const Divider(),
          _rowUsdWidget(
              context, Strings.withdrawAmount, Strings.depositMoneyAmount),
          const Divider(),
          _rowUsdWidget(context, Strings.feesJust, Strings.feesMoney),
          const Divider(),
          _rowUsdWidget(context, Strings.total, Strings.totalDepositMoney),
        ],
      ),
    );
  }

  PrimaryButtonWidget _depositButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: Strings.withdraw,
      onPressed: () {
        Get.toNamed(Routes.withdrawMoneySuccessScreen);
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
          style: CustomStyler.otpVerificationDescriptionStyle,
        ),
        Row(
          children: [
            Text(
              amount,
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
