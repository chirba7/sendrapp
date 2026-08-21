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

class SignUpCongratulationsScreen extends StatelessWidget {
  const SignUpCongratulationsScreen({Key? key}) : super(key: key);

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
        _upperWidget(context),
        _okayButtonWidget(context)
      ],
    );
  }


  Container _upperWidget(BuildContext context) {
    return Container(
      color: CustomColor.whiteColor,
      child: Column(
        mainAxisAlignment: mainStart,
        crossAxisAlignment: crossStart,
        children: [
          addVerticalSpace(100.h),
          _titleWidget(context),
          addVerticalSpace(100.h),
          _imageWidget(context),
          addVerticalSpace(40.h),

        ],
      ),
    );
  }


  Container _titleWidget(BuildContext context){
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize),
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
            Strings.signUpCongTitle,
            style: CustomStyler.onboardTitleStyle,
          ),
          addVerticalSpace(5.h),
          Text(
            Strings.signUpCongDes,
            style: CustomStyler.onboardDesStyle,
          ),
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
            Strings.congratulationsImage,
            width: double.infinity,
            fit: BoxFit.fill,
          ),
        ],
      ),
    );
  }

  PrimaryButtonWidget _okayButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: Strings.okay,
      onPressed: () {
        Get.toNamed(Routes.signInScreen);
      },
      borderColor: CustomColor.whiteColor,
      backgroundColor: CustomColor.whiteColor,
      textColor: CustomColor.textColor,
    );
  }
}
