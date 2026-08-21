import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/size.dart';

class SmallContainerWidget extends StatelessWidget {
  const SmallContainerWidget({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.containerName,
  }) : super(key: key);

  final VoidCallback onPressed;
  final IconData icon;
  final String containerName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossCenter,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF40B8A9),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Icon(
              icon,
              color: CustomColor.whiteColor,
            ),
          )
        ),
        addVerticalSpace(5.h),
        Text(
          containerName,
          style: CustomStyler.cardSmallContainerStyle,
        )
      ],
    );
  }
}
