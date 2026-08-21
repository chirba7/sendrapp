import 'package:flutter/material.dart';

class WalletModel {
  Color backgroundColor;
  String countryImage;
  String currencyOne;
  String currencyTwo;
  String money;

  WalletModel(
      {required this.backgroundColor,
      required this.countryImage,
      required this.currencyOne,
      required this.currencyTwo,
      required this.money});
}
