import 'package:flutter/material.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/dimsensions.dart';

class CustomStyler {
  static var splashTitleStyle = const TextStyle(
    color: CustomColor.textColor,
    fontSize: 14,
  );

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

  static var signInStyle = const TextStyle(
    color: CustomColor.textColor,
    fontSize: 20,
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


  static var currentBalanceStyler = TextStyle(
    color: CustomColor.whiteColor.withOpacity(0.5),
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static var currentBalanceStyle = TextStyle(
    color: CustomColor.whiteColor.withOpacity(0.5),
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );



  static var currentBalanceUsdStyle = const TextStyle(
    color: CustomColor.whiteColor,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );


  static var currentBalanceMoneyStyle = const TextStyle(
    color: CustomColor.whiteColor,
    fontSize: 20,
    fontWeight: FontWeight.w400,
  );


  static var cardSmallContainerStyle = const TextStyle(
    color: CustomColor.whiteColor,
    fontSize: 8,
    fontWeight: FontWeight.w700,
  );


  static var transactionsHistoryStyle = const TextStyle(
    color: CustomColor.textColor,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );



  static var moneyDepositTitleStyle = const TextStyle(
      color: CustomColor.textColor,
      fontSize: 13,
      fontWeight: FontWeight.w700);


  static var moneyDepositDateStyle = const TextStyle(
      color: CustomColor.gray,
      fontSize: 7,
      fontWeight: FontWeight.w700);

  static var moneyDepositDollarStyle = const TextStyle(
      color: CustomColor.textColor,
      fontSize: 14,
      fontWeight: FontWeight.w700);


  static var profileNameStyle = const TextStyle(
      color: CustomColor.textColor,
      fontSize: 22,
      fontWeight: FontWeight.w700);


  static var userIdStyle = const TextStyle(
      color: CustomColor.gray,
      fontSize: 14,
      fontWeight: FontWeight.w700);


  static var editProfileStyle = const TextStyle(
    color: CustomColor.textColor,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );


  static var withdrawMoneyStyle = const TextStyle(
    color: CustomColor.whiteColor,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );


  static var withdrawMoneyAmountStyle = const TextStyle(
    color: CustomColor.whiteColor,
    fontSize: 40,
    fontWeight: FontWeight.w700,
  );

  static var availableBalanceStyle = const TextStyle(
    color: CustomColor.whiteColor,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static var textStyler = TextStyle(
    color: CustomColor.primaryColor,
    fontSize: Dimensions.mediumTextSize,
    fontWeight: FontWeight.w500,
  );



  static var aboutUsDesStyle = const TextStyle(
    color: CustomColor.gray,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );


  static var copyrightStyle = const TextStyle(
      color: CustomColor.textColor,
      fontSize: 16,
      fontWeight: FontWeight.w700
  );


  static var websiteStyle = TextStyle(
      color: CustomColor.textColor.withOpacity(0.4),
      fontSize: 12,
      fontWeight: FontWeight.w700
  );

  static var paymentMethodTextStyle = const TextStyle(
    fontWeight: FontWeight.w500,
    color: CustomColor.gray,
    // fontSize: 20,
  );






}
