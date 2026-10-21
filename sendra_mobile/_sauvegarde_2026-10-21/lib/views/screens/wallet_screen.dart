import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:walletium/data/wallet_list.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/views/screens/drawer_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.primaryBackgroundColor,
      drawer: const DrawerScreen(),
      appBar: AppBar(
        backgroundColor: CustomColor.primaryColor,
        iconTheme: const IconThemeData(color: CustomColor.whiteColor),
        title: const Text(Strings.wallet),
        elevation: 0,
      ),
      body: _bodyWidget(context),
    );
  }

  GridView _bodyWidget(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 3 / 3,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemCount: walletList.length,
      itemBuilder: (BuildContext context, int index) {
        return _containerWidget(
            context,
            walletList[index].backgroundColor,
            walletList[index].countryImage,
            walletList[index].currencyOne,
            walletList[index].currencyTwo,
            walletList[index].money,
          );
      },
    );
  }

  Container _containerWidget(
      BuildContext context,
      Color backgroundColor,
      String countryImage,
      String currencyOne,
      String currencyTwo,
      String money) {
    return Container(
      margin: EdgeInsets.all(Dimensions.marginSize * 0.5),
      padding: EdgeInsets.symmetric(
          horizontal: Dimensions.defaultPaddingSize * 0.5,
          vertical: Dimensions.defaultPaddingSize * 0.5),
      decoration: BoxDecoration(
          color: backgroundColor, borderRadius: BorderRadius.circular(20.r)),
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
                  addVerticalSpace(15.h),
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
                        currencyOne,
                        style: CustomStyler.currentBalanceUsdStyle,
                      ),
                    ],
                  ),
                  addVerticalSpace(5.h),
                  Text(
                    currencyTwo,
                    style: CustomStyler.currentBalanceStyle,
                  ),
                  addVerticalSpace(5.h),
                  Row(
                    mainAxisAlignment: mainStart,
                    children: [
                      Text(
                        '\$ ' + money,
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
