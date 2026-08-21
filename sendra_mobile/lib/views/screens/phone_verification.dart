import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/sign_up_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import 'package:walletium/widgets/inputs/input_text_field.dart';
import 'package:walletium/widgets/inputs/password_input_text_field.dart';
import 'package:walletium/widgets/labels/text_labels_widget.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';

class SignUpScreenOTP extends StatelessWidget {
  SignUpScreenOTP({Key? key}) : super(key: key);
  final _controller = Get.put(SignUpController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _bodyWidget(context),
    );
  }

  ScrollConfiguration _bodyWidget(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Strings.signInBg),
            fit: BoxFit.fill,
          ),
        ),
        child: ListView(
          children: [
            _backButton(context),
            _titleAndDesWidget(context),
            addVerticalSpace(35.h),
            _inputWidgets(context),
            _signUpButtonWidget(context),
            _policyWidget(context),
            _alreadyHaveAccWidget(context),
          ],
        ),
      ),
    );
  }

  Container _backButton(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.all(Dimensions.marginSize),
      child: Row(
        children: [
          const BackButtonWidget(
            backButtonImage: Strings.backButton,
          ),
          addHorizontalSpace(10.w),
          Text(
            Strings.signUp,
            style: CustomStyler.signInStyle,
          )
        ],
      ),
    );
  }

  Container _titleAndDesWidget(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(Dimensions.marginSize),
      child: Column(
        crossAxisAlignment: crossStart,
        children: [
          Text(
            Strings.signUpTitle,
            style: CustomStyler.signInTitleStyle,
          ),
          addVerticalSpace(10.h),
          Text(
            Strings.signUpDescription,
            style: CustomStyler.onboardDesStyle,
          ),
        ],
      ),
    );
  }

  Form _inputWidgets(BuildContext context) {
    return Form(
      key: _controller.formKey,
      child: Column(
        children: [
          TextLabelsWidget(
            textLabels: Strings.name,
            textColor: CustomColor.whiteColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: InputTextField(
              controller: _controller.nameController,
              hintText: Strings.enterFullName,
              backgroundColor: Colors.transparent,
              hintTextColor: CustomColor.gray,
              borderColor: CustomColor.gray,
            ),
          ),
          TextLabelsWidget(
            textLabels: Strings.phoneNumber,
            textColor: CustomColor.whiteColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: InputTextField(
              controller: _controller.phoneNumberController,
              hintText: Strings.enterPhoneNumber,
              backgroundColor: Colors.transparent,
              hintTextColor: CustomColor.gray,
              borderColor: CustomColor.gray,
            ),
          ),
          TextLabelsWidget(
            textLabels: Strings.password,
            textColor: CustomColor.whiteColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: PasswordInputTextField(
              controller: _controller.passwordController,
              hintText: Strings.enterPassword,
            ),
          ),
          TextLabelsWidget(
            textLabels: Strings.confirmPassword,
            textColor: CustomColor.whiteColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: PasswordInputTextField(
              controller: _controller.confirmPasswordController,
              hintText: Strings.confirmPassword,
            ),
          )
        ],
      ),
    );
  }

  PrimaryButtonWidget _signUpButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: Strings.signUp,
      onPressed: () {
        Get.toNamed(Routes.phoneVerificationScreen);
      },
      borderColor: CustomColor.textColor,
      backgroundColor: CustomColor.textColor,
      textColor: CustomColor.whiteColor,
    );
  }

  Container _policyWidget(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        margin: EdgeInsets.all(Dimensions.marginSize * 0.5),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: Strings.terms,
            style: TextStyle(color: CustomColor.whiteColor),
            children: <TextSpan>[
              TextSpan(
                text: Strings.policy,
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    Get.toNamed(Routes.signUpScreen);
                  },
                style: TextStyle(
                    color: CustomColor.whiteColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ));
  }

  Container _alreadyHaveAccWidget(BuildContext context) {
    return Container(
        alignment: Alignment.bottomCenter,
        margin: EdgeInsets.all(Dimensions.marginSize),
        child: Row(
          mainAxisAlignment: mainCenter,
          children: [
            const Text(
              Strings.alreadyHaveAcc,
              style: TextStyle(
                color: CustomColor.whiteColor,
              ),
            ),
            GestureDetector(
              onTap: () {
                Get.back();
              },
              child: const Text(
                Strings.signIn,
                style: TextStyle(
                    color: CustomColor.whiteColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ));
  }
}
