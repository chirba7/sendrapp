import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../utils/custom_color.dart';

class TextFieldOtp extends StatelessWidget {
  const TextFieldOtp(
      {Key? key,
      required this.controller,
      required InputDecoration decoration,
      required TextInputType keyboardType})
      : super(key: key);

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      controller: controller,
      appContext: context,
      length: 6,
      obscureText: false,
      keyboardType: TextInputType.number,
      textStyle: const TextStyle(color: CustomColor.textColor),
      animationType: AnimationType.fade,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(7),
        selectedColor: CustomColor.gray,
        activeColor: CustomColor.gray,
        inactiveColor: CustomColor.gray,
        fieldHeight: 52,
        fieldWidth: 50,
        activeFillColor: Colors.transparent,
      ),
      onChanged: (String value) {},
    );
  }
}
