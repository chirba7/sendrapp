import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:walletium/controller/sign_up_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import 'package:walletium/widgets/inputs/input_text_field.dart';
import 'package:walletium/widgets/labels/text_labels_widget.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';

String generateVerificationCode() {
  // Generate a random 6-digit verification code
  Random random = Random();
  int code = random.nextInt(900000) +
      100000; // Generates a random number between 100000 and 999999
  return code.toString();
}

void main() {
  String verificationCode = generateVerificationCode();
  print('Code de vérification généré: $verificationCode');
}

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _controller = Get.put(SignUpController());

  static final _formKey1 = new GlobalKey<FormState>();
  Key _k4 = new GlobalKey();

  FirebaseAuth _auth = FirebaseAuth.instance;
  String _verificationId = '';

  // Correction : pointait vers l'ancien backend PHP legacy (demo.sendra.sn),
  // complètement déconnecté de l'API Laravel utilisée par le login
  // (Strings.apiURI) — un compte créé ici n'existait jamais côté login.
  Future<void> _verifyPhoneNumber() async {
    String phoneNumber = _controller.phoneNumberController.text.trim().replaceAll(' ', '');

    var response = await http.post(
      Uri.parse(Strings.apiURI + 'send-verification-code'),
      body: {
        'telephone': phoneNumber,
      },
    );

    Map<String, dynamic> jsonResponse = {};
    try {
      jsonResponse = jsonDecode(response.body);
    } catch (_) {}

    if (response.statusCode == 200 && jsonResponse['success'] == true) {
      print('Le code de vérification a été envoyé avec succès !');
      Get.toNamed(
        Routes.phoneVerificationScreen,
        arguments: {
          'auth': _auth,
          'verificationId': phoneNumber,
        },
      );
    } else {
      print('Echec de l’envoi du code de vérification.');
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Erreur'),
          content: Text(jsonResponse['message']?.toString() ??
              'Impossible d\'envoyer le code de vérification.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _bodyWidget(context),
    );
  }

  ScrollConfiguration _bodyWidget(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white, // Blanc en haut
              Colors.green.shade900, // Vert foncé en bas
            ],
          ),
        ),
        child: ListView(
          physics: BouncingScrollPhysics(),
          children: [
            _backButton(context),
            _titleAndDesWidget(context),
            addVerticalSpace(35.h),
            _inputWidgets(context),
            _signUpButtonWidget(context),
            //_policyWidget(context),
            _alreadyHaveAccWidget(context),
          ],
        ),
      ),

    );
  }

  Container _backButton(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.all(Dimensions.marginSize),
      child: Row(
        children: [
          const BackButtonWidget(
            backButtonImage: Strings.backButton,
          ),
          addHorizontalSpace(10.w),
          Text(
            Strings.signUp,
            style: TextStyle(
              color: CustomColor.textColor,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }

  Container _titleAndDesWidget(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(Dimensions.marginSize),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*Text(
            Strings.signUpTitle,
            style: CustomStyler.signInTitleStyle,
          ),
          (10.h),
          Text(
            Strings.signUpDescription,
            style: CustomStyler.onboardDesStyle,
          ),*/
        ],
      ),
    );
  }

  Form _inputWidgets(BuildContext context) {
    return Form(
      key: _formKey1,
      child: Column(
        children: [
          TextLabelsWidget(
            textLabels: Strings.phoneNumber,
            textColor: CustomColor.whiteColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: InputTextField(
              controller: _controller.phoneNumberController,
              hintText: Strings.enterPhoneNumber,
              backgroundColor: Colors.transparent,
              hintTextColor: CustomColor.gray,
              borderColor: CustomColor.gray,
            ),
          ),
        ],
      ),
    );
  }

  PrimaryButtonWidget _signUpButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: Strings.signUp,
      onPressed: () {
        _verifyPhoneNumber();
      },
      borderColor: CustomColor.textColor,
      backgroundColor: CustomColor.textColor,
      textColor: CustomColor.whiteColor,
    );
  }

  Container _policyWidget(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        margin: EdgeInsets.all(Dimensions.marginSize * 0.5),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: Strings.terms,
            style: TextStyle(color: CustomColor.whiteColor),
            children: <TextSpan>[
              TextSpan(
                text: Strings.policy,
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    Get.toNamed(Routes.signUpScreen);
                  },
                style: TextStyle(
                    color: CustomColor.whiteColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ));
  }

  Container _alreadyHaveAccWidget(BuildContext context) {
    return Container(
        alignment: Alignment.bottomCenter,
        margin: EdgeInsets.all(Dimensions.marginSize),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Strings.alreadyHaveAcc,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: CustomColor.whiteColor,
              ),
            ),
            GestureDetector(
              onTap: () {
                Get.back();
              },
              child:
              Text(
                Strings.signIn,
                style: TextStyle(
                  color: CustomColor.whiteColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ));
  }
}
