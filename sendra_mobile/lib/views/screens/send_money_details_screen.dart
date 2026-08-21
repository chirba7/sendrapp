import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/send_money_details_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import 'package:walletium/widgets/inputs/input_text_field.dart';
import 'package:walletium/widgets/labels/text_labels_widget.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';

class SendMoneyDetailsScreen extends StatelessWidget {
  SendMoneyDetailsScreen({Key? key}) : super(key: key);
  final _controller = Get.put(SendMoneyDetailsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.sendMoneyDetails,
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
        _inputWidgets(context),
        _detailsWidget(context),
        _sendMoneyButtonWidget(context),
      ],
    );
  }

  Form _inputWidgets(BuildContext context) {
    return Form(
      key: _controller.formKey,
      child: Column(
        children: [
          TextLabelsWidget(
            textLabels: Strings.recipient,
            textColor: CustomColor.textColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: InputTextField(
              controller: _controller.emailContainer,
              hintText: Strings.enterEmail,
              backgroundColor: Colors.transparent,
              hintTextColor: CustomColor.gray,
              borderColor: CustomColor.gray,
            ),
          ),
          TextLabelsWidget(
            textLabels: Strings.description,
            textColor: CustomColor.textColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: InputTextField(
              controller: _controller.paymentDescriptionController,
              hintText: Strings.paymentDescription,
              backgroundColor: Colors.transparent,
              hintTextColor: CustomColor.gray,
              borderColor: CustomColor.gray,
            ),
          ),
        ],
      ),
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
          _rowWidget(
              context, Strings.sendingAmount, Strings.sendingAmountMoney),
          const Divider(),
          _rowWidget(context, Strings.feesJust, Strings.feesMoney),
          const Divider(),
          _rowWidget(context, Strings.yourRecipientWillGet,
              Strings.yourRecipientWillGetMoney),
          const Divider(),
          addVerticalSpace(10.h),
          _rowWidget(
              context, Strings.youPayInTotal, Strings.youPayInTotalMoney),
        ],
      ),
    );
  }

  Container _sendMoneyButtonWidget(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: Dimensions.marginSize * 0.5),
      child: PrimaryButtonWidget(
        title: Strings.sendMoney,
        onPressed: () {
          Get.toNamed(Routes.sendMoneySuccessScreen);
        },
        borderColor: CustomColor.primaryColor,
        backgroundColor: CustomColor.primaryColor,
        textColor: CustomColor.whiteColor,
      ),
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
