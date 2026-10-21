import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/withdraw_money_details_controller.dart';
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
import 'package:walletium/widgets/others/country_code_picker_widget.dart';

class WithdrawMoneyDetailsScreen extends StatelessWidget {
  WithdrawMoneyDetailsScreen({Key? key}) : super(key: key);
  final _controller = Get.put(WithdrawMoneyDetailsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.withdrawMoneyDetails,
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
        addVerticalSpace(50.h),
        _detailsWidget(context),
        _continueButtonWidget(context),
      ],
    );
  }

  Form _inputWidgets(BuildContext context) {
    return Form(
      key: _controller.formKey,
      child: Column(
        mainAxisAlignment: mainStart,
        crossAxisAlignment: crossStart,
        children: [
          TextLabelsWidget(
            textLabels: Strings.accountHolderName,
            textColor: CustomColor.textColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: InputTextField(
              controller: _controller.accountHolderNameController,
              hintText: Strings.accountHolderName,
              backgroundColor: Colors.transparent,
              hintTextColor: CustomColor.gray,
              borderColor: CustomColor.gray,
            ),
          ),
          TextLabelsWidget(
            textLabels: Strings.accountNumber,
            textColor: CustomColor.textColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: InputTextField(
              controller: _controller.accountNumberController,
              hintText: Strings.accountNumber,
              backgroundColor: Colors.transparent,
              hintTextColor: CustomColor.gray,
              borderColor: CustomColor.gray,
            ),
          ),
          TextLabelsWidget(
            textLabels: Strings.selectCountry,
            textColor: CustomColor.textColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: const CountryCodePickerWidget(),
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
              context, Strings.withdrawAmount, Strings.depositAmountMoney),
          const Divider(),
          _rowWidget(context, Strings.feesJust, Strings.feesMoney),
          const Divider(),
          addVerticalSpace(10.h),
          _rowWidget(context, Strings.total, Strings.totalDepositMoney),
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
          Get.toNamed(Routes.withdrawMoneyReviewScreen);
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
