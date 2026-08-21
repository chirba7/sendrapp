import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/otp_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import 'package:walletium/widgets/inputs/otp_input_text_field.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';

class OtpVerificationScreen extends StatelessWidget {
  OtpVerificationScreen({Key? key}) : super(key: key);
  final controller = Get.put(OtpController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.primaryColor,
      appBar: AppBar(
        title: const Text(
          Strings.otpVerification,
          style: TextStyle(color: CustomColor.textColor),
        ),
        leading: const BackButtonWidget(
          backButtonImage: Strings.backButton,
        ),
        backgroundColor: CustomColor.whiteColor,
        elevation: 0,
      ),
      body: _bodyWidget(context),
    );
  }

  ListView _bodyWidget(BuildContext context) {
    return ListView(
      children: [
        _upperWidget(context),
        _imageWidget(context),
        addVerticalSpace(30.h),
        _submitButtonWidget(context),
      ],
    );
  }

  Container _upperWidget(BuildContext context) {
    return Container(
      color: CustomColor.whiteColor,
      child: Column(
        children: [
          addVerticalSpace(20.h),
          _timeWidget(context),
          addVerticalSpace(40.h),
          _otpMiddleSection(context),
          _titleWidget(context),
        ],
      ),
    );
  }

  Container _timeWidget(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize),
      child: Row(
        mainAxisAlignment: mainStart,
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: CustomColor.primaryColor,
          ),
          addHorizontalSpace(5.w),
          const Text(
            Strings.time,
            style: TextStyle(
                color: CustomColor.textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Container _otpMiddleSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize),
      child: TextFieldOtp(
        controller: controller.otpController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Enter OTP',
          // Add validation to make OTP field required
          errorText:
              controller.otpController.text.isEmpty ? 'OTP is required' : null,
        ),
      ),
    );
  }

  Container _titleWidget(BuildContext context) {
    return Container(
        margin: EdgeInsets.all(Dimensions.marginSize),
        child: Row(
          mainAxisAlignment: mainStart,
          children: [
            Text(
              Strings.enterTheCodeSentTo,
              textAlign: TextAlign.center,
              style: CustomStyler.otpVerificationDescriptionStyle,
            ),
            addHorizontalSpace(10.w),
            Text(
              Strings.enterPhoneNumber,
              textAlign: TextAlign.center,
              style: CustomStyler.otpVerificationDescriptionStyle,
            ),
          ],
        ));
  }

  Container _imageWidget(BuildContext context) {
    return Container(
      color: CustomColor.primaryBackgroundColor,
      child: Column(
        children: [
          Image.asset(
            Strings.otpImage,
            width: double.infinity,
            fit: BoxFit.fill,
          ),
        ],
      ),
    );
  }

  PrimaryButtonWidget _submitButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: Strings.submit,
      onPressed: () {
        Get.toNamed(Routes.resetPasswordScreen);
      },
      borderColor: CustomColor.whiteColor,
      backgroundColor: CustomColor.whiteColor,
      textColor: CustomColor.textColor,
    );
  }
}
