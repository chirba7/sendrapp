import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/strings.dart';

class CountryCodePickerWidget extends StatelessWidget {
  const CountryCodePickerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60.h,
      decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: CustomColor.gray, width: 1),
          borderRadius: BorderRadius.circular(12.r)
      ),
      padding: EdgeInsets.all(Dimensions.defaultPaddingSize * 0.2),
      child: CountryCodePicker(
        showOnlyCountryWhenClosed: true,
        showDropDownButton: true,
        initialSelection: Strings.selectCountry,
        backgroundColor: CustomColor.gray,
        alignLeft: true,
      ),
    );
  }
}
