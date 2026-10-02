import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/widgets/others/dropdown_widget.dart';

class PaymentMethodInputTextFieldWidget extends StatelessWidget {
  const PaymentMethodInputTextFieldWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      // margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5,),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: CustomColor.gray)),
      child: DropdownWidget(),
    );
  }
}
