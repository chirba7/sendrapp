import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/request_money_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import 'package:walletium/widgets/inputs/amount_input_textfield_widget.dart';
import 'package:walletium/widgets/inputs/input_text_field.dart';
import 'package:walletium/widgets/labels/text_labels_widget.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';
import 'package:walletium/widgets/others/country_code_picker_widget.dart';
import 'package:walletium/widgets/others/datetime.dart';

class RequestMoneyScreen extends StatelessWidget {
  RequestMoneyScreen({Key? key}) : super(key: key);
  final _controller = Get.put(RequestMoneyController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.requestMoney,
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
        _continueButtonWidget(context),
        addVerticalSpace(20.h),
      ],
    );
  }

  Form _inputWidgets(BuildContext context) {
    return Form(
      key: _controller.formKey,
      child: Column(
        children: [
          TextLabelsWidget(
            textLabels: Strings.payerName,
            textColor: CustomColor.textColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: InputTextField(
              controller: _controller.payerNameController,
              hintText: Strings.enterPayerName,
              backgroundColor: Colors.transparent,
              hintTextColor: CustomColor.gray,
              borderColor: CustomColor.gray,
            ),
          ),
          TextLabelsWidget(
            textLabels: Strings.email,
            textColor: CustomColor.textColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: InputTextField(
              controller: _controller.emailController,
              hintText: Strings.enterEmail,
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
              // borderColor: CustomColor.gray,
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
              maxLine: 6,
              controller: _controller.descriptionController,
              hintText: Strings.paymentDescription,
              backgroundColor: Colors.transparent,
              hintTextColor: CustomColor.gray,
              borderColor: CustomColor.gray,
            ),
          ),
          TextLabelsWidget(
            textLabels: Strings.paymentDueBy,
            textColor: CustomColor.textColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: const DateTimeWidget(),
          ),
        ],
      ),
    );
  }

  PrimaryButtonWidget _continueButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: Strings.conTinue,
      onPressed: () {
        Get.toNamed(Routes.requestMoneyReviewScreen);
      },
      borderColor: CustomColor.primaryColor,
      backgroundColor: CustomColor.primaryColor,
      textColor: CustomColor.whiteColor,
    );
  }
}
