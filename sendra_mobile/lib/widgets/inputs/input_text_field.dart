import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/strings.dart';

class InputTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool? readOnly;
  final Color backgroundColor;
  final Color hintTextColor;
  final Color borderColor;
  final int? maxLine;
  final IconData? iconData;

  const InputTextField(
      {Key? key,
      required this.controller,
      required this.hintText,
      this.keyboardType,
      this.readOnly = false,
      required this.backgroundColor,
      required this.hintTextColor,
      this.maxLine,
      this.iconData,
      required this.borderColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 50.h,
        maxHeight: 100.h,
      ),
      child: TextFormField(

        // maxLines: maxLine,
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
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radius * 1),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Dimensions.radius * 1),
            borderSide: BorderSide(color: borderColor, width: 1),
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
          contentPadding: EdgeInsets.symmetric(
              horizontal: Dimensions.defaultPaddingSize * 0.7,
              vertical: Dimensions.defaultPaddingSize * 0.6),
          hintText: hintText,
          hintStyle: TextStyle(
              color: hintTextColor, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
