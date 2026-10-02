import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.aboutUs,
          style: TextStyle(color: CustomColor.whiteColor),
        ),
        leading: const BackButtonWidget(
          backButtonImage: Strings.backButtonWhite,
        ),
        backgroundColor: CustomColor.primaryColor,
        elevation: 0,
      ),
      body: _bodyWidget(context),
    );
  }

  Widget _bodyWidget(BuildContext context) {
    return Scrollbar(
      child: ListView(
        children: [
          addVerticalSpace(20.h),
          _imageWidget(context),
          addVerticalSpace(20.h),
          _aboutUsDescription(context),
          _copyRightWidget(context)
        ],
      ),
    );
  }

  Container _imageWidget(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/EPAVIE2.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Container _aboutUsDescription(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(Dimensions.marginSize * 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I.	Conditions Générales d\'Utilisation (CGU)',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: [
                Shadow(
                  color: Colors.grey.withOpacity(0.5),
                  blurRadius: 2,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          addVerticalSpace(20.h),
          Text(
            Strings.aboutUsPartOne,
            textAlign: TextAlign.justify,
            style: CustomStyler.aboutUsDesStyle,
          ),
          addVerticalSpace(20.h),
          Text(
            Strings.aboutUsPartTwo,
            textAlign: TextAlign.justify,
            style: CustomStyler.aboutUsDesStyle,
          ),
          addVerticalSpace(20.h),
          Text(
            'II.	Protection de la Vie Privée',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: [
                Shadow(
                  color: Colors.grey.withOpacity(0.5),
                  blurRadius: 2,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          Text(
            Strings.aboutUsPartThree,
            textAlign: TextAlign.justify,
            style: CustomStyler.aboutUsDesStyle,
          ),
          addVerticalSpace(20.h),
          Text(
            Strings.aboutUsPartFour,
            textAlign: TextAlign.justify,
            style: CustomStyler.aboutUsDesStyle,
          ),
          addVerticalSpace(20.h),

          Text(
            'III.  Rappel de l\'Usage et de la Destination de l\'Application',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: [
                Shadow(
                  color: Colors.grey.withOpacity(0.5),
                  blurRadius: 2,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
          addVerticalSpace(20.h),
          Text(
            'Notre application de gestion des signalements simplifie le processus de signalement et de suivi des incidents. Avec une interface conviviale, des performances optimales et un stockage sécurisé des données, les utilisateurs peuvent signaler et suivre les incidents avec facilité. Notre application offre une expérience fluide et efficace pour gérer les signalements, améliorant ainsi la gestion des problèmes dans la communauté.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black87,
              wordSpacing: -1,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Container _copyRightWidget(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            Strings.copyright,
            style: CustomStyler.copyrightStyle,
          ),
          Text(
            Strings.websiteLink,
            style: CustomStyler.websiteStyle,
          ),
        ],
      ),
    );
  }
}
