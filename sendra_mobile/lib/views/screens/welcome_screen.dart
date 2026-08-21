import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.primaryBackgroundColor,
      body: _bodyWidget(context),
    );
  }

  ListView _bodyWidget(BuildContext context) {
    return ListView(
      // mainAxisAlignment: mainSpaceBet,
      children: [
        _upperBackgroundImage(context),
        _buttonWidget(context),
        _downBackgroundImage(context),
      ],
    );
  }

  Stack _upperBackgroundImage(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.37,
          alignment: Alignment.topCenter,
          child: Image.asset(
            Strings.welcomeUpBg,
            width: double.infinity,
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
            top: MediaQuery.of(context).size.height * 0.22,
            left: 40,
            child: Column(
              mainAxisAlignment: mainStart,
              crossAxisAlignment: crossStart,
              children: [
                Image.asset(
                  Strings.splashLogo,
                  width: 180.w,
                ),
                addVerticalSpace(20.h),
                Text(
                  Strings.welcomeTitle,
                  style: CustomStyler.onboardTitleStyle,
                ),
                addVerticalSpace(5.h),
                Text(
                  Strings.welcomeDescription,
                  style: CustomStyler.onboardDesStyle,
                ),
              ],
            ))
      ],
    );
  }

  Container _buttonWidget(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      child: Column(
        mainAxisAlignment: mainCenter,
        crossAxisAlignment: crossCenter,
        children: [
          PrimaryButtonWidget(
            backgroundColor: CustomColor.primaryColor,
            borderColor: CustomColor.primaryColor,
            textColor: CustomColor.whiteColor,
            onPressed: () {
              Get.toNamed(Routes.signInScreen);
            },
            title: Strings.signIn,
          ),
          PrimaryButtonWidget(
            backgroundColor: CustomColor.textColor,
            borderColor: CustomColor.textColor,
            textColor: CustomColor.whiteColor,
            onPressed: () {
              Get.toNamed(Routes.signUpScreen);
            },
            title: Strings.signUp,
          )
        ],
      ),
    );
  }

  Container _downBackgroundImage(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.33,
      alignment: Alignment.bottomCenter,
      child: Image.asset(
        Strings.welcomeDownBg,
        width: double.infinity,
        fit: BoxFit.fill,
      ),
    );
  }
}
