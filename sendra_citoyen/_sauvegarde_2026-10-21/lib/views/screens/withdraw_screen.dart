import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/withdraw_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import 'package:walletium/widgets/inputs/amount_input_textfield_widget.dart';
import 'package:walletium/widgets/inputs/payment_method_input_textfield_widget.dart';
import 'package:walletium/widgets/labels/text_labels_widget.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';

class WithdrawScreen extends StatelessWidget {
  WithdrawScreen({Key? key}) : super(key: key);
  final _controller = Get.put(WithdrawController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.primaryBackgroundColor,
      body: _bodyWidget(context),
    );
  }

  ListView _bodyWidget(BuildContext context) {
    return ListView(
      children: [
        _backWithBalanceWidget(context),
        _inputWidget(context),
        _detailsWidget(context),
        _continueButtonWidget(context),
      ],
    );
  }

  Container _backWithBalanceWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.defaultPaddingSize * 0.5, vertical: Dimensions.defaultPaddingSize),
      decoration: BoxDecoration(
          color: CustomColor.primaryColor,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30.r),
              bottomRight: Radius.circular(30.r))),
      child: Column(
        mainAxisAlignment: mainSpaceBet,
        children: [
          Row(
            children: [
              const BackButtonWidget(
                backButtonImage: Strings.backButtonWhite,
              ),
              addHorizontalSpace(10.w),
              Text(
                Strings.withdrawMoney,
                style: CustomStyler.withdrawMoneyStyle,
              )
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: Dimensions.defaultPaddingSize * 0.7),
            child: Column(
              mainAxisAlignment: mainCenter,
              crossAxisAlignment: crossCenter,
              children: [
                Row(
                  mainAxisAlignment: mainCenter,
                  children: [
                    Text(
                      Strings.dollarSign,
                      style: CustomStyler.withdrawMoneyAmountStyle,
                    ),
                    addHorizontalSpace(5.w),
                    Text(
                      Strings.availableMoneyAmount,
                      style: CustomStyler.withdrawMoneyAmountStyle,
                    ),
                  ],
                ),
                addVerticalSpace(10.h),
                Text(
                  Strings.availableBalance,
                  style: CustomStyler.availableBalanceStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Form _inputWidget(BuildContext context) {
    return Form(
      key: _controller.formKey,
      child: Column(
        children: [
          addVerticalSpace(40.h),
          TextLabelsWidget(
            textLabels: Strings.withdrawTo,
            textColor: CustomColor.textColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: const PaymentMethodInputTextFieldWidget()
          ),
          addVerticalSpace(20.h),
          TextLabelsWidget(
            textLabels: Strings.amount,
            textColor: CustomColor.textColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: AmountInputTextFieldWidget(
              controller: _controller.amountController,
              hintText: Strings.amount,
              backgroundColor: Colors.transparent,
              hintTextColor: CustomColor.gray,
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
          _rowWidget(context, Strings.feesJust, Strings.feesMoney),
          const Divider(),
          _rowWidget(
              context, Strings.amountToWithdraw, Strings.totalDepositMoney),
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
          Get.toNamed(Routes.withdrawMoneyDetailsScreen);
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
