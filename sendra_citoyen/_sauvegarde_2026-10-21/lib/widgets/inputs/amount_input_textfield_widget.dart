import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/others/currency_selector_widget.dart';

class AmountInputTextFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool? readOnly;
  final Color backgroundColor;
  final Color hintTextColor;
  final int? maxLine;
  final IconData? iconData;
  final String? labelTextName;

  const AmountInputTextFieldWidget(
      {Key? key,
        required this.controller,
        required this.hintText,
        this.keyboardType,
        this.readOnly = false,
        required this.backgroundColor,
        required this.hintTextColor,
        this.maxLine,
        this.iconData, this.labelTextName})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: maxLine,
      readOnly: readOnly!,
      style: CustomStyler.textFieldLableStyle,
      controller: controller,
      keyboardType: keyboardType,
      validator: (String? value) {
        if (value!.isEmpty) {
          return null;
        } else {
          return Strings.pleaseFillOutTheField;
        }
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radius * 1),
          borderSide: const BorderSide(color: Color(0xFFE9EDEE), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radius * 1),
          borderSide: const BorderSide(color: Color(0xFFE9EDEE), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radius * 1),
          borderSide:
          const BorderSide(color: CustomColor.primaryColor, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radius * 1),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radius * 1),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        // prefixIcon: Icon(iconData, color: CustomColor.whiteColor,),
        fillColor: backgroundColor,
        contentPadding: EdgeInsets.only(
            left: Dimensions.defaultPaddingSize * 0.7,),
        suffixIcon: Container(
          width: MediaQuery.of(context).size.width * 0.38,
          height: 60.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EDEE),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(Dimensions.radius * 1),
              bottomRight: Radius.circular(Dimensions.radius * 1),
            ),
            border: Border.all(color: const Color(0xFFE9EDEE))
          ),
          child: const CurrencySelectorWidget()
        ),
        // suffixText: Strings.usd,
        labelText: labelTextName,
        labelStyle: const TextStyle(
          color: CustomColor.gray
        ),
        hintText: hintText,
        hintStyle: TextStyle(
            color: hintTextColor, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
