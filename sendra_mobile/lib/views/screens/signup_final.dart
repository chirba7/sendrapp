import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Import fluttertoast
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

class SignUpFinalScreen extends StatefulWidget {
  @override
  _SignUpFinalScreenState createState() => _SignUpFinalScreenState();
}

class _SignUpFinalScreenState extends State<SignUpFinalScreen> {
  final _controller = Get.put(SignUpController());

  static final _formKey1 = new GlobalKey<FormState>();
  Key _k5 = new GlobalKey();

  FirebaseAuth _auth = FirebaseAuth.instance;
  String _verificationId = '';

  bool _validateFields() {
    if (_controller.phoneNumberController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Numéro de téléphone obligatoire',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return false;
    }
    if (_controller.nameController.text.isEmpty) {
      // Show an error or toast message for empty name
      Fluttertoast.showToast(
        msg: 'Nom obligatoire',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return false;
    }
    if (_controller.passwordController.text.isEmpty) {
      // Show an error or toast message for empty password
      Fluttertoast.showToast(
        msg: 'Mot de passe obligatoire',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return false;
    }
    if (_controller.confirmPasswordController.text.isEmpty) {
      // Show an error or toast message for empty confirm password
      Fluttertoast.showToast(
        msg: 'Confirmer le mot de passe',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return false;
    }
    if (_controller.passwordController.text !=
        _controller.confirmPasswordController.text) {
      // Show an error or toast message for password mismatch
      Fluttertoast.showToast(
        msg: 'Les deux mots de passe doivent correspondre',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return false;
    }
    return true;
  }

  // Correction : pointait vers l'ancien backend PHP legacy, déconnecté de
  // l'API Laravel (Strings.apiURI) utilisée pour le login. /register exige
  // first_name/last_name séparés (un seul champ "nom" existe dans ce
  // formulaire — on le découpe sur le premier espace).
  Future<void> _verifyPhoneNumber() async {
    if (!_validateFields()) {
      // Validation failed, stop the process
      return;
    }
    String phoneNumber = _controller.phoneNumberController.text.trim().replaceAll(' ', '');
    String fullName = _controller.nameController.text.trim();
    String password = _controller.passwordController.text.trim();

    final nameParts = fullName.split(RegExp(r'\s+'));
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : nameParts.first;

    var response = await http.post(
      Uri.parse(Strings.apiURI + 'register'),
      body: {
        'telephone': phoneNumber,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      print('Inscription terminée avec succés!');
      Get.toNamed(
        Routes.signUpCongratulationsScreen,
        arguments: {
          //'auth': _auth,
        },
      );
    } else {
      Map<String, dynamic> jsonResponse = {};
      try {
        jsonResponse = jsonDecode(response.body);
      } catch (_) {}
      print('Echec de l’inscription : ${response.body}');
      Fluttertoast.showToast(
        msg: jsonResponse['message']?.toString() ?? 'Échec de l\'inscription.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
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
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Strings.signInBg),
            fit: BoxFit.fill,
          ),
        ),
        child: ListView(
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
            style: CustomStyler.signInStyle,
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
          TextLabelsWidget(
            textLabels: Strings.name,
            textColor: CustomColor.whiteColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: InputTextField(
              controller: _controller.nameController,
              hintText: Strings.enterFullName,
              backgroundColor: Colors.transparent,
              hintTextColor: CustomColor.gray,
              borderColor: CustomColor.gray,
            ),
          ),
          TextLabelsWidget(
            textLabels: Strings.password,
            textColor: CustomColor.whiteColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: InputTextField(
              controller: _controller.passwordController,
              hintText: Strings.enterPassword,
              backgroundColor: Colors.transparent,
              hintTextColor: CustomColor.gray,
              borderColor: CustomColor.gray,
            ),
          ),
          TextLabelsWidget(
            textLabels: Strings.confirmPassword,
            textColor: CustomColor.whiteColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: InputTextField(
              controller: _controller.confirmPasswordController,
              hintText: Strings.enterConfirmPassword,
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
            const Text(
              Strings.alreadyHaveAcc,
              style: TextStyle(
                color: CustomColor.whiteColor,
              ),
            ),
            GestureDetector(
              onTap: () {
                Get.back();
              },
              child: const Text(
                Strings.signIn,
                style: TextStyle(
                    color: CustomColor.whiteColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ));
  }
}
