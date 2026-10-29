import 'package:flutter/material.dart';
import 'package:walletium/utils/custom_color.dart';

class CustomStyler {
  static var onboardTitleStyle = const TextStyle(
    color: CustomColor.textColor,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static var onboardDesStyle = const TextStyle(
    color: CustomColor.gray,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static var signInTitleStyle = const TextStyle(
    color: CustomColor.textColor,
    fontSize: 30,
    fontWeight: FontWeight.w700,
  );

  static var textFieldLableStyle = const TextStyle(
    color: CustomColor.gray,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static var otpVerificationDescriptionStyle = const TextStyle(
    color: CustomColor.gray,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static var aboutUsDesStyle = const TextStyle(
    color: CustomColor.gray,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );

  static var copyrightStyle = const TextStyle(
      color: CustomColor.textColor, fontSize: 16, fontWeight: FontWeight.w700);

  static var websiteStyle = TextStyle(
      color: CustomColor.textColor.withValues(alpha: 0.4),
      fontSize: 12,
      fontWeight: FontWeight.w700);
}
