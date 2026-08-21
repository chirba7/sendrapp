import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';

class WithdrawHistoryScreen extends StatelessWidget {
  const WithdrawHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.withdrawHistory,
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
    return ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: 10,
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
                      const Icon(
                        FontAwesomeIcons.arrowUpFromBracket,
                        color: Color(0xFF1F3EA6),
                        size: 30,
                      ),
                      addHorizontalSpace(20.w),
                      Column(
                        mainAxisAlignment: mainCenter,
                        crossAxisAlignment: crossStart,
                        children: [
                          Text(
                            Strings.moneyWithdraw,
                            style: CustomStyler.moneyDepositTitleStyle,
                          ),
                          Text(
                            Strings.moneyDepositDate,
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
