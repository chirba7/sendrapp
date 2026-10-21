
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';

class DepositMoneySuccessScreen extends StatelessWidget {
  const DepositMoneySuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          Strings.depositMoney,
          style: TextStyle(
            color: CustomColor.whiteColor,
          ),
        ),
        backgroundColor: CustomColor.primaryColor,
      ),
      body: _bodyWidget(context),
    );
  }

  ListView _bodyWidget(BuildContext context) {
    return ListView(
      children: [
        addVerticalSpace(100.h),
        _imageWidget(context),
        addVerticalSpace(20.h),
        _titleWidget(context),
        addVerticalSpace(40.h),


        _okayButtonWidget(context)
      ],
    );
  }

  Container _imageWidget(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Image.asset(Strings.confirmImage),
    );
  }

  Column _titleWidget(BuildContext context){
    return Column(
      mainAxisAlignment: mainCenter,
      crossAxisAlignment: crossCenter,
      children: [
        Text(Strings.success, style: CustomStyler.onboardTitleStyle,),
        Text(Strings.depositSuccessDescription, style: CustomStyler.otpVerificationDescriptionStyle,),
      ],
    );
  }



  PrimaryButtonWidget _okayButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: Strings.okay,
      onPressed: () {
        Get.toNamed(Routes.bottomNavigationScreen);
      },
      borderColor: CustomColor.primaryColor,
      backgroundColor: CustomColor.primaryColor,
      textColor: CustomColor.whiteColor,
    );
  }
}
