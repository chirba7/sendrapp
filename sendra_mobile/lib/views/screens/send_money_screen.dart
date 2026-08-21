import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/send_money_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import 'package:walletium/widgets/inputs/amount_input_textfield_widget.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';

class SendMoneyScreen extends StatelessWidget {
  SendMoneyScreen({Key? key}) : super(key: key);
  final _controller = Get.put(SendMoneyController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.sendMoney,
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
        _youSendWidget(context),
        _detailsWidget(context),
        _continueButtonWidget(context)
      ],
    );
  }

  Form _youSendWidget(BuildContext context) {
    return Form(
      key: _controller.formKey,
      child: Column(
        children: [
          addVerticalSpace(40.h),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: AmountInputTextFieldWidget(
                labelTextName: Strings.youSend,
                controller: _controller.youSendController,
                hintText: Strings.youSend,
                backgroundColor: CustomColor.whiteColor,
                hintTextColor: CustomColor.textColor),
          ),
          addVerticalSpace(20.h),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: AmountInputTextFieldWidget(
                labelTextName: Strings.recipientGets,
                controller: _controller.recipientGetsController,
                hintText: Strings.recipientGets,
                backgroundColor: CustomColor.whiteColor,
                hintTextColor: CustomColor.textColor),
          )
        ],
      ),
    );
  }

  Container _detailsWidget(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(Dimensions.marginSize),
      child: Column(
        mainAxisAlignment: mainStart,
        crossAxisAlignment: crossStart,
        children: [
          Text(
            Strings.exchangeRate,
            style: CustomStyler.otpVerificationDescriptionStyle,
          ),
          addVerticalSpace(5.h),
          Text(
            Strings.fees,
            style: CustomStyler.otpVerificationDescriptionStyle,
          ),
          addVerticalSpace(5.h),
          Text(
            Strings.totalPayableAmount,
            style: CustomStyler.otpVerificationDescriptionStyle,
          ),
        ],
      ),
    );
  }

  Container _continueButtonWidget(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: Dimensions.marginSize * 0.5),
      child: PrimaryButtonWidget(
        title: Strings.conTinue,
        onPressed: () {
          Get.toNamed(Routes.sendMoneyDetailsScreen);
        },
        borderColor: CustomColor.primaryColor,
        backgroundColor: CustomColor.primaryColor,
        textColor: CustomColor.whiteColor,
      ),
    );
  }
}
