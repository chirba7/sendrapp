import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/reset_password_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import 'package:walletium/widgets/inputs/password_input_text_field.dart';
import 'package:walletium/widgets/labels/text_labels_widget.dart';

class ResetPasswordScreen extends StatelessWidget {
  ResetPasswordScreen({Key? key}) : super(key: key);
  final _controller = Get.put(ResetPasswordController());


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.primaryColor,
      body: _bodyWidget(context),
    );
  }

  ListView _bodyWidget(BuildContext context) {
    return ListView(
      children: [
        addVerticalSpace(20.h),
        _upperWidget(context),
        _imageWidget(context),
        addVerticalSpace(10.h),
        _resetButtonWidget(context),
      ],
    );
  }

  Container _upperWidget(BuildContext context) {
    return Container(
      color: CustomColor.whiteColor,
      child: Column(
        children: [
          _titleWidget(context),
          addVerticalSpace(20.h),
          _inputWidgets(context),
          addVerticalSpace(20.h),

        ],
      ),
    );
  }


  Container _titleWidget(BuildContext context) {
    return Container(
        margin: EdgeInsets.all(Dimensions.marginSize),
        child: Column(
          mainAxisAlignment: mainCenter,
          crossAxisAlignment: crossCenter,
          children: [
            Text(
              Strings.resetPassword,
              textAlign: TextAlign.center,
              style: CustomStyler.signInTitleStyle,
            ),
            addHorizontalSpace(10.w),
            Text(
              Strings.resetPasswordDescription,
              textAlign: TextAlign.center,
              style: CustomStyler.otpVerificationDescriptionStyle,
            ),
          ],
        ));
  }





  Form _inputWidgets(BuildContext context) {
    return Form(
      key: _controller.formKey,
      child: Column(
        children: [
          TextLabelsWidget(textLabels: Strings.newPassword, textColor: CustomColor.textColor,),
          Container(
            margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: PasswordInputTextField(
              controller: _controller.newPasswordController,
              hintText: Strings.enterNewPassword,),
          ),
          TextLabelsWidget(textLabels: Strings.confirmPassword, textColor: CustomColor.textColor,),
          Container(
            margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: PasswordInputTextField(
              controller: _controller.confirmPasswordController,
              hintText: Strings.enterConfirmPassword,),
          )
        ],
      ),
    );
  }







  Container _imageWidget(BuildContext context) {
    return Container(
      color: CustomColor.primaryBackgroundColor,
      child: Column(
        children: [
          Image.asset(
            Strings.resetPasswordImage,
            width: double.infinity,
            fit: BoxFit.fill,
          ),
        ],
      ),
    );
  }


  PrimaryButtonWidget _resetButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: Strings.resetPassword,
      onPressed: () {
        Get.toNamed(Routes.resetPasswordCongratulationsScreen);
      },
      borderColor: CustomColor.whiteColor,
      backgroundColor: CustomColor.whiteColor,
      textColor: CustomColor.textColor,
    );
  }
}
