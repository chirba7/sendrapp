import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/views/screens/drawer_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.primaryBackgroundColor,
      drawer: const DrawerScreen(),
      appBar: AppBar(
        backgroundColor: CustomColor.primaryColor,
        iconTheme: const IconThemeData(color: CustomColor.whiteColor),
        title: const Text(Strings.notification),
        elevation: 0,
      ),
      body: _bodyWidget(context),
    );
  }

  dynamic _bodyWidget(BuildContext context) {
    return _transactionHistoryListWidget(context);
  }

  ListView _transactionHistoryListWidget(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: 6,
        itemBuilder: (BuildContext context, int index) {
          return SizedBox(
            height: 60.h,
            child: Padding(
              padding: EdgeInsets.all(Dimensions.defaultPaddingSize * 0.3),
              child: Row(
                mainAxisAlignment: mainSpaceBet,
                crossAxisAlignment: crossCenter,
                children: [
                  Row(
                    mainAxisAlignment: mainStart,
                    crossAxisAlignment: crossCenter,
                    children: [
                      Container(
                        width: 50.h,
                        height: 50.h,
                        decoration: const BoxDecoration(
                          color: CustomColor.textColor,
                          image: DecorationImage(
                              image: AssetImage(Strings.notificationImage),
                              fit: BoxFit.cover),
                          shape: BoxShape.circle,
                        ),
                      ),
                      addHorizontalSpace(10.w),
                      Column(
                        mainAxisAlignment: mainCenter,
                        crossAxisAlignment: crossStart,
                        children: [
                          Text(
                            Strings.notificationTitle,
                            style: CustomStyler.moneyDepositTitleStyle,
                          ),
                          Text(
                            Strings.notificationTime,
                            style: CustomStyler.moneyDepositDateStyle,
                          ),
                        ],
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        Strings.dollarSign,
                        style: CustomStyler.moneyDepositDollarStyle,
                      ),
                      Text(
                        Strings.depositMoneyAmount,
                        style: CustomStyler.moneyDepositDollarStyle,
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
  }
}
