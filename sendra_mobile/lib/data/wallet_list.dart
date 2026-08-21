import 'package:flutter/material.dart';
import 'package:walletium/model/wallet_model.dart';
import 'package:walletium/utils/strings.dart';

List<WalletModel> walletList = [
  WalletModel(
    backgroundColor: Colors.blue,
    countryImage: Strings.usaImage,
    currencyOne: Strings.usd,
    currencyTwo: Strings.unitedStatesDollar,
    money: Strings.currentBalanceMoney,
  ),
  WalletModel(
    backgroundColor: Colors.blueAccent,
    countryImage: Strings.audImage,
    currencyOne: Strings.aud,
    currencyTwo: Strings.australianDollar,
    money: Strings.australianDollarMoney,
  ),
  WalletModel(
    backgroundColor: Colors.deepOrange,
    countryImage: Strings.gbpImage,
    currencyOne: Strings.gbp,
    currencyTwo: Strings.britishPound,
    money: Strings.britishPoundMoney,
  ),
  WalletModel(
    backgroundColor: Colors.purple,
    countryImage: Strings.jpyImage,
    currencyOne: Strings.jpy,
    currencyTwo: Strings.japaneseYen,
    money: Strings.japaneseYenMoney,
  ),
  WalletModel(
    backgroundColor: Colors.orangeAccent,
    countryImage: Strings.inrImage,
    currencyOne: Strings.inr,
    currencyTwo: Strings.indianRupee,
    money: Strings.indianRupeeMoney,
  ),
];
