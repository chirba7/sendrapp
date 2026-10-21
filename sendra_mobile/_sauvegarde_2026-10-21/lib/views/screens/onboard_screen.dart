import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/onboard_controller.dart';
import 'package:walletium/data/onboard_data.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/onboard_button.dart';

class OnboardScreen extends StatelessWidget {
  OnboardScreen({Key? key}) : super(key: key);
  final _controller = Get.put(OnBoardController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.primaryColor,
      body: _bodyWidget(context),
    );
  }

  Column _bodyWidget(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 500.w,
          color: CustomColor.whiteColor,
          child: PageView.builder(
            physics: const ClampingScrollPhysics(),
            controller: _controller.pageController,
            onPageChanged: _controller.selectedIndex,
            itemCount: onboardData.length,
            itemBuilder: (context, index) {
              return Column(
                mainAxisAlignment: mainSpaceBet,
                crossAxisAlignment: crossStart,
                children: [
                  addVerticalSpace(20.h),
                  //logo
                  _logoWidget(context),
                  Column(
                    crossAxisAlignment: crossStart,

                    children: [
                      //title
                      Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: Dimensions.marginSize,
                            vertical: Dimensions.marginSize * 0.5),
                        child: Text(
                          onboardData[index].title,
                          textAlign: TextAlign.start,
                          style: CustomStyler.onboardTitleStyle,
                        ),
                      ),
                      //dot
                      Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: Dimensions.marginSize,
                            vertical: Dimensions.marginSize * 0.5),
                        child: Row(
                          mainAxisAlignment: mainSpaceBet,
                          children: [
                            Obx(() => Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: List.generate(
                                onboardData.length,
                                    (index) => AnimatedContainer(
                                  duration:
                                  const Duration(milliseconds: 200),
                                  margin: EdgeInsets.only(right: 10.w),
                                  height: 10.h,
                                  width: 10.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: index <=
                                        _controller
                                            .selectedIndex.value
                                        ? CustomColor.textColor
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                      //description
                      Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: Dimensions.marginSize,
                            vertical: Dimensions.marginSize * 0.5),
                        child: Text(
                          onboardData[index].description,
                          textAlign: TextAlign.start,
                          style: CustomStyler.onboardDesStyle,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: crossStart,
                    children: [
                      Container(
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(onboardData[index].image, width: double.infinity, fit: BoxFit.fill,),
                      )
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        _buttonWidget(context),
      ],
    );
  }

  Container _logoWidget(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.all(Dimensions.marginSize),
      child: Image.asset(
        Strings.splashLogo,
        width: 150.w,

      ),
    );
  }

  Column _buttonWidget(BuildContext context) {
    return Column(
      mainAxisAlignment: mainCenter,
      children: [
        addVerticalSpace(20.h),
        OnboardButton(
          onPressed: () {
            _controller.onTapCheck();
          },
        ),
      ],
    );
  }
}
