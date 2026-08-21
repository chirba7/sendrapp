import 'package:flutter/material.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/strings.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.primaryBackgroundColor,
      body: Center(
        child: Container(
            margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize),
            child: Image.asset(Strings.splashLogo)),
      ),
    );
  }
}
