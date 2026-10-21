import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:walletium/controller/reset_password_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import 'package:walletium/widgets/inputs/password_input_text_field.dart';
import 'package:walletium/widgets/labels/text_labels_widget.dart';

/// Étape 3 (finale) du flux "mot de passe oublié" : soumet le nouveau mot de
/// passe à /reset-password, qui exige que ce numéro ait déjà un code vérifié
/// (voir otp_verification_screen.dart) — sinon 400.
class ResetPasswordScreen extends StatefulWidget {
  final String phone;

  ResetPasswordScreen({Key? key})
      : phone = Get.arguments as String,
        super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _controller = Get.put(ResetPasswordController());
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _resetPassword() async {
    if (!_controller.formKey.currentState!.validate()) return;

    final newPassword = _controller.newPasswordController.text;
    final confirmPassword = _controller.confirmPasswordController.text;

    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${Strings.apiURI}reset-password'),
        body: {
          'telephone': widget.phone,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      ).timeout(const Duration(seconds: 20));

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        if (!mounted) return;
        Get.offAllNamed(Routes.resetPasswordCongratulationsScreen);
        return;
      }

      setState(() {
        _errorMessage = jsonResponse['message']?.toString() ??
            'Impossible de réinitialiser le mot de passe.';
        _isSubmitting = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Connexion indisponible. Vérifiez votre accès à Internet.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.primaryColor,
      body: _bodyWidget(context),
    );
  }

  ListView _bodyWidget(BuildContext context) {
    return ListView(
      children: [
        addVerticalSpace(20.h),
        _upperWidget(context),
        _imageWidget(context),
        addVerticalSpace(10.h),
        if (_errorMessage != null) _errorWidget(context),
        _resetButtonWidget(context),
      ],
    );
  }

  Container _upperWidget(BuildContext context) {
    return Container(
      color: CustomColor.whiteColor,
      child: Column(
        children: [
          _titleWidget(context),
          addVerticalSpace(20.h),
          _inputWidgets(context),
          addVerticalSpace(20.h),
        ],
      ),
    );
  }

  Container _titleWidget(BuildContext context) {
    return Container(
        margin: EdgeInsets.all(Dimensions.marginSize),
        child: Column(
          mainAxisAlignment: mainCenter,
          crossAxisAlignment: crossCenter,
          children: [
            Text(
              Strings.resetPassword,
              textAlign: TextAlign.center,
              style: CustomStyler.signInTitleStyle,
            ),
            addHorizontalSpace(10.w),
            Text(
              Strings.resetPasswordDescription,
              textAlign: TextAlign.center,
              style: CustomStyler.otpVerificationDescriptionStyle,
            ),
          ],
        ));
  }

  Form _inputWidgets(BuildContext context) {
    return Form(
      key: _controller.formKey,
      child: Column(
        children: [
          TextLabelsWidget(textLabels: Strings.newPassword, textColor: CustomColor.textColor,),
          Container(
            margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: PasswordInputTextField(
              controller: _controller.newPasswordController,
              hintText: Strings.enterNewPassword,),
          ),
          TextLabelsWidget(textLabels: Strings.confirmPassword, textColor: CustomColor.textColor,),
          Container(
            margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: PasswordInputTextField(
              controller: _controller.confirmPasswordController,
              hintText: Strings.enterConfirmPassword,),
          )
        ],
      ),
    );
  }

  Container _errorWidget(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize),
      child: Text(
        _errorMessage!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
      ),
    );
  }

  Container _imageWidget(BuildContext context) {
    return Container(
      color: CustomColor.primaryBackgroundColor,
      child: Column(
        children: [
          Image.asset(
            Strings.resetPasswordImage,
            width: double.infinity,
            fit: BoxFit.fill,
          ),
        ],
      ),
    );
  }

  PrimaryButtonWidget _resetButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: _isSubmitting ? '...' : Strings.resetPassword,
      onPressed: _isSubmitting ? () {} : _resetPassword,
      borderColor: CustomColor.whiteColor,
      backgroundColor: CustomColor.whiteColor,
      textColor: CustomColor.textColor,
    );
  }
}
