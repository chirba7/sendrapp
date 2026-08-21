import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';

class OnboardButton extends StatelessWidget {
  const OnboardButton({Key? key, required this.onPressed}) : super(key: key);

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 60.h,
        decoration: BoxDecoration(
          color: CustomColor.whiteColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(Dimensions.marginSize),
        padding: EdgeInsets.all(Dimensions.defaultPaddingSize * 0.5),
        child: Row(
          mainAxisAlignment: mainSpaceBet,
          children: const [
            Text(Strings.letsGetStarted, style: TextStyle(
              color: CustomColor.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),),
            Icon(Icons.arrow_forward, color: CustomColor.textColor, size: 20,)
          ],
        ),

      ),
    );
  }
}
