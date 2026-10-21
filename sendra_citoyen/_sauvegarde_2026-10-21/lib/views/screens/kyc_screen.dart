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
import 'package:walletium/widgets/others/back_button_widget.dart';
import 'package:walletium/widgets/others/kyc_selector_widget.dart';

class KycScreen extends StatelessWidget {
  const KycScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.kyc,
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
        addVerticalSpace(20.h),
        _titleWidget(context),
        const KycSelectorWidget(),
        _uploadNid(context),
        addVerticalSpace(20.h),
        _submitButtonWidget(context)
      ],
    );
  }

  Container _titleWidget(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
      child: Column(
        mainAxisAlignment: mainCenter,
        crossAxisAlignment: crossCenter,
        children: [
          Text(
            Strings.verifyAccount,
            style: CustomStyler.onboardTitleStyle,
          ),
          Text(
            Strings.verifyAccountDescription,
            textAlign: TextAlign.center,
            style: CustomStyler.otpVerificationDescriptionStyle,
          ),
        ],
      ),
    );
  }


  Row _uploadNid(BuildContext context) {
    return Row(
      mainAxisAlignment: mainCenter,
      children: [
        _uploadWidget(context, Strings.nidOneImage),
        addHorizontalSpace(20.w),
        _uploadWidget(
          context,
          Strings.nidTwoImage,
        ),
      ],
    );
  }

  PrimaryButtonWidget _submitButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: Strings.submit,
      onPressed: () {
        Get.toNamed(Routes.bottomNavigationScreen);
      },
      borderColor: CustomColor.primaryColor,
      backgroundColor: CustomColor.primaryColor,
      textColor: CustomColor.whiteColor,
    );
  }

  Container _uploadWidget(BuildContext context, String nidPic) {
    return Container(
      padding: EdgeInsets.all(Dimensions.defaultPaddingSize * 0.5),
      child: Column(
        crossAxisAlignment: crossCenter,
        children: [
          Image.asset(nidPic, width: 80, height: 70,),
          addVerticalSpace(20.h),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 80.w,
              height: 50.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border:
                      Border.all(color: CustomColor.primaryColor, width: 2)),
              child: const Text(
                Strings.upload,
                style: TextStyle(
                    color: CustomColor.primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ),
          )
        ],
      ),
    );
  }

}
