import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';

// ignore: must_be_immutable
class DateTimeWidget extends StatefulWidget {
  const DateTimeWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<DateTimeWidget> createState() => _DateTimeWidgetState();
}

class _DateTimeWidgetState extends State<DateTimeWidget> {
  DateTime date = DateTime(2022, 12, 24);
  bool isEmpty = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Dimensions.radius * 1),
        border: Border.all(color: CustomColor.gray)
      ),
      padding: EdgeInsets.symmetric(horizontal: Dimensions.defaultPaddingSize * 0.7),
      child:Row(
        mainAxisAlignment: mainSpaceBet,
        children: [
          Text(
            isEmpty ? Strings.dMy : '${date.day}-${date.month}-${date.year}',
            style: CustomStyler.textFieldLableStyle,
          ),
          InkWell(
              onTap: () async {
                DateTime? newDate = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2023),
                );

                if (newDate == null) return;
                setState(() {
                  date = newDate;
                  isEmpty = !isEmpty;
                });
                // Get.to(() => date = newDate);
              },
              child: const Icon(Icons.calendar_today, color: CustomColor.gray,),),
          // addHorizontalSpace(10.w),

        ],
      ),
    );
  }
}
