import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:walletium/controller/otp_controller.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import 'package:walletium/widgets/inputs/otp_input_text_field.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';

/// Étape 2 du flux "mot de passe oublié" : vérifie le code envoyé par SMS
/// via l'API (/verify-code), puis passe le numéro déjà vérifié à l'écran de
/// réinitialisation (reset-password exige un code vérifié pour ce numéro).
class OtpVerificationScreen extends StatefulWidget {
  final String phone;

  OtpVerificationScreen({Key? key})
      : phone = Get.arguments as String,
        super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final controller = Get.put(OtpController());
  bool _isVerifying = false;
  String? _errorMessage;

  Future<void> _verifyOtp() async {
    final otp = controller.otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir le code reçu par SMS.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${Strings.apiURI}verify-code'),
        body: {'code': otp, 'telephone': widget.phone},
      ).timeout(const Duration(seconds: 20));

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        if (!mounted) return;
        Get.toNamed(Routes.resetPasswordScreen, arguments: widget.phone);
        return;
      }

      setState(() {
        _errorMessage = _avecEssaisRestants(jsonResponse,
            'Code de vérification invalide.');
        _isVerifying = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage =
            'Connexion indisponible. Vérifiez votre accès à Internet.';
        _isVerifying = false;
      });
    }
  }

  /// Message du serveur, suivi du nombre d'essais restants s'il est donné
  /// (5 essais par code depuis le 29/10/2026).
  String _avecEssaisRestants(Map<String, dynamic> corps, String parDefaut) {
    final message = corps['message']?.toString() ?? parDefaut;
    final restants = int.tryParse(corps['essais_restants']?.toString() ?? '');
    if (restants == null || restants <= 0) return message;
    return '$message ($restants essai${restants > 1 ? 's' : ''} restant${restants > 1 ? 's' : ''})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.primaryColor,
      appBar: AppBar(
        title: const Text(
          Strings.otpVerification,
          style: TextStyle(color: CustomColor.textColor),
        ),
        leading: const BackButtonWidget(
          backButtonImage: Strings.backButton,
        ),
        backgroundColor: CustomColor.whiteColor,
        elevation: 0,
      ),
      body: SafeArea(child: _bodyWidget(context)),
    );
  }

  ListView _bodyWidget(BuildContext context) {
    return ListView(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 24),
      children: [
        _upperWidget(context),
        _imageWidget(context),
        addVerticalSpace(30),
        _submitButtonWidget(context),
      ],
    );
  }

  Container _upperWidget(BuildContext context) {
    return Container(
      color: CustomColor.whiteColor,
      child: Column(
        children: [
          addVerticalSpace(20),
          _otpMiddleSection(context),
          _titleWidget(context),
          if (_errorMessage != null) _errorWidget(context),
        ],
      ),
    );
  }

  Container _otpMiddleSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.marginSize),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Code de vérification'),
          const SizedBox(height: 8),
          TextFieldOtp(
            controller: controller.otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Code de vérification',
            ),
          ),
        ],
      ),
    );
  }

  Container _titleWidget(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Dimensions.marginSize),
      // Correction : les deux Text (libellé + numéro) sans Expanded
      // débordaient de la Row de 59px sur les numéros/écrans un peu longs
      // (ex: écran d'OTP pendant le flux mot de passe oublié).
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
              child: Text(
            Strings.enterTheCodeSentTo,
            textAlign: TextAlign.center,
            style: CustomStyler.otpVerificationDescriptionStyle,
          )),
          addHorizontalSpace(6),
          Expanded(
            child: Text(
              widget.phone,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: CustomStyler.otpVerificationDescriptionStyle,
            ),
          ),
        ],
      ),
    );
  }

  Container _errorWidget(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.marginSize),
      child: Text(
        _errorMessage!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
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
            // Illustration plus petite sur un écran bas (clavier ouvert,
            // Fold fermé) pour garder le champ et le bouton visibles.
            height: (MediaQuery.sizeOf(context).height * .25)
                .clamp(110.0, 220.0)
                .toDouble(),
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  PrimaryButtonWidget _submitButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: _isVerifying ? '...' : Strings.submit,
      onPressed: _isVerifying ? () {} : _verifyOtp,
      borderColor: CustomColor.whiteColor,
      backgroundColor: CustomColor.whiteColor,
      textColor: CustomColor.textColor,
    );
  }
}
