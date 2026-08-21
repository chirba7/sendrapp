import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:walletium/controller/otp_controller.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import 'package:walletium/widgets/inputs/otp_input_text_field.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';

import '../../controller/sign_up_controller.dart';
import '../../routes/routes.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final FirebaseAuth _auth;
  final String _verificationId;

  PhoneVerificationScreen({Key? key})
      : _auth = Get.arguments['auth'],
        _verificationId = Get.arguments['verificationId'],
        super(key: key);

  @override
  _PhoneVerificationScreenState createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final controller = Get.put(OtpController());
  final _controller_signup = Get.put(SignUpController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.primaryColor,
      appBar: AppBar(
        title: const Text(
          Strings.phoneVerification,
          style: TextStyle(color: CustomColor.textColor),
        ),
        leading: const BackButtonWidget(
          backButtonImage: Strings.backButton,
        ),
        backgroundColor: CustomColor.whiteColor,
        elevation: 0,
      ),
      body: _bodyWidget(context),
    );
  }

  // Correction : pointait vers l'ancien backend PHP legacy, déconnecté de
  // l'API Laravel (Strings.apiURI) utilisée pour le login/register.
  Future<void> _signInWithOTP(BuildContext context) async {
    String otp = controller.otpController.text.trim();
    String phone = _controller_signup.phoneNumberController.text.trim().replaceAll(' ', '');

    // Send an HTTP POST request to the API endpoint

    try {
      // Create a map of the request body
      Map<String, String> requestBody = {'code': otp, 'telephone': phone};

      // Send an HTTP POST request to the API endpoint
      final response = await http.post(
        Uri.parse(Strings.apiURI + 'verify-code'),
        body: requestBody,
      );
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      print(jsonResponse);
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        // Successful authentication, do something (e.g., navigate to the home screen).

        Get.toNamed(Routes.signUpFinalScreen);
      } else {
        // Authentication failed, show an error message.
        print(
            'Echec de l’authentification !');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                  ),
                  SizedBox(width: 8),
                  Text('Erreur'),
                ],
              ),
              content: Text('La vérification OTP a échoué.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                ),
                SizedBox(width: 8),
                Text('Erreur'),
              ],
            ),
            content: Text('Le code de validation est erroné !'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  ListView _bodyWidget(BuildContext context) {
    return ListView(
      children: [
        _upperWidget(context),
        _imageWidget(context),
        addVerticalSpace(30.h),
        _submitButtonWidget(context),
      ],
    );
  }

  Container _upperWidget(BuildContext context) {
    return Container(
      color: CustomColor.whiteColor,
      child: Column(
        children: [
          addVerticalSpace(20.h),
          _timeWidget(context),
          addVerticalSpace(20.h),
          _otpMiddleSection(context),
          _titleWidget(context),
        ],
      ),
    );
  }

  Container _timeWidget(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: CustomColor.primaryColor,
          ),
          addHorizontalSpace(5.w),
          const Text(
            Strings.time,
            style: TextStyle(
                color: CustomColor.textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Container _otpMiddleSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize),
      child: TextFieldOtp(
        controller: controller.otpController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Enter OTP',
          // Add validation to make OTP field required
          errorText:
              controller.otpController.text.isEmpty ? 'OTP is required' : null,
        ),
      ),
    );
  }

  Container _titleWidget(BuildContext context) {
    var _controller = Get.put(SignUpController());
    return Container(
      margin: EdgeInsets.all(Dimensions.marginSize),
      child: Column(
        // Use a Column to split the string into two rows
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Strings.enterTheCodeSentTo,
            textAlign: TextAlign.start,
            style: CustomStyler.otpVerificationDescriptionStyle,
          ),
          Row(
            children: [
              Text(
                _controller.phoneNumberController.text.trim(),
                textAlign: TextAlign.start,
                style: CustomStyler.otpVerificationDescriptionStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Container _imageWidget(BuildContext context) {
    return Container(
      color: CustomColor.primaryBackgroundColor,
      child: Column(
        children: [
          Image.asset(
            Strings.otpImage,
            width: double.infinity,
            fit: BoxFit.fill,
          ),
        ],
      ),
    );
  }

  PrimaryButtonWidget _submitButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: Strings.submit,
      onPressed: () {
        // Check if the OTP field is not empty before proceeding
        if (controller.otpController.text.isEmpty) {
          // Show an error message if OTP field is empty
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text('Error'),
                  ],
                ),
                content: Text('S’il vous plaît entrer le mot de passe à usage unique'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          // Proceed with OTP verification
          _signInWithOTP(context);
        }
      },
      borderColor: CustomColor.whiteColor,
      backgroundColor: CustomColor.whiteColor,
      textColor: CustomColor.textColor,
    );
  }
}
