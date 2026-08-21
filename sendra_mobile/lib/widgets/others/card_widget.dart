import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';

class CardWidget extends StatelessWidget {
  const CardWidget({
    Key? key,
    required this.countryImage,
  }) : super(key: key);
  final String countryImage;

  @override
  Widget build(BuildContext context) {
    return _bodyWidget(context);
  }

  Column _bodyWidget(BuildContext context) {
    return Column(
      children: [
        _cardSectionWidget(context),
      ],
    );
  }

  Container _cardSectionWidget(BuildContext context) {
    return Container(
      // width: 250.w,
      // height: 200.h,
      margin: EdgeInsets.all(Dimensions.marginSize * 0.5),
      padding: EdgeInsets.symmetric(
          horizontal: Dimensions.defaultPaddingSize,
          vertical: Dimensions.defaultPaddingSize * 0.5),
      decoration: BoxDecoration(
          color: const Color(0xFF40B8A9),
          borderRadius: BorderRadius.circular(15.r)),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: crossEnd,
            children: [
              Column(
                mainAxisAlignment: mainEnd,
                crossAxisAlignment: crossEnd,
                children: [
                  Row(
                    mainAxisAlignment: mainEnd,
                    children: [
                      Text(
                        Strings.currentBalance,
                        style: CustomStyler.currentBalanceStyle,
                      ),
                    ],
                  ),
                  addVerticalSpace(20.h),
                ],
              ),
              Column(
                // Column(
                crossAxisAlignment: crossStart,
                children: [
                  Row(
                    children: [
                      Image.asset(countryImage),
                      addHorizontalSpace(5.w),
                      Text(
                        Strings.usd,
                        style: CustomStyler.currentBalanceUsdStyle,
                      ),
                    ],
                  ),
                  addVerticalSpace(5.h),
                  Text(
                    Strings.unitedStatesDollar,
                    style: CustomStyler.currentBalanceStyle,
                  ),
                  addVerticalSpace(5.h),
                  Row(
                    mainAxisAlignment: mainStart,
                    children: [
                      Text(
                        Strings.dollarSign,
                        style: CustomStyler.currentBalanceMoneyStyle,
                      ),
                      addHorizontalSpace(5.w),
                      Text(
                        Strings.currentBalanceMoney,
                        style: CustomStyler.currentBalanceMoneyStyle,
                      ),
                    ],
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
