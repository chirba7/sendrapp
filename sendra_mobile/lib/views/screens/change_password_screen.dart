import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import 'package:walletium/widgets/labels/text_labels_widget.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';

class ChangePasswordScreen extends StatefulWidget {
  ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String userId = '';
  String? oldPasswordError;
  String? newPasswordError;
  String? confirmPasswordError;
  bool showOldPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;
  bool passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    getUserId();
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.changePassword,
          style: TextStyle(color: CustomColor.textColor),
        ),
        leading: const BackButtonWidget(
          backButtonImage: Strings.backButtonWhite,
        ),
        backgroundColor: CustomColor.whiteColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.marginSize),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              TextLabelsWidget(
                textLabels: Strings.oldPassword,
                textColor: CustomColor.textColor,
              ),
              TextFormField(
                controller: oldPasswordController,
                obscureText: !showOldPassword,
                onChanged: (value) {
                  validateFields();
                },
                decoration: InputDecoration(
                  hintText: Strings.oldPassword,
                  errorText: oldPasswordError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showOldPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: CustomColor.textColor,
                    ),
                    onPressed: () {
                      setState(() {
                        showOldPassword = !showOldPassword;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              TextLabelsWidget(
                textLabels: Strings.newPassword,
                textColor: CustomColor.textColor,
              ),
              TextFormField(
                controller: newPasswordController,
                obscureText: !showNewPassword,
                onChanged: (value) {
                  validateFields();
                },
                decoration: InputDecoration(
                  hintText: Strings.newPassword,
                  errorText: newPasswordError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: CustomColor.textColor,
                    ),
                    onPressed: () {
                      setState(() {
                        showNewPassword = !showNewPassword;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              TextLabelsWidget(
                textLabels: Strings.confirmPassword,
                textColor: CustomColor.textColor,
              ),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: !showConfirmPassword,
                onChanged: (value) {
                  validateFields();
                  setState(() {
                    showConfirmPassword = value.isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  hintText: Strings.confirmPassword,
                  errorText: confirmPasswordError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showConfirmPassword)
                        Icon(
                          passwordsMatch
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: passwordsMatch
                              ? Colors.green
                              : Colors.red,
                        ),
                      IconButton(
                        icon: Icon(
                          showConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: CustomColor.textColor,
                        ),
                        onPressed: () {
                          setState(() {
                            showConfirmPassword = !showConfirmPassword;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Colors.green[900], // Utilisation d'une seule couleur pour un aspect uniforme
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: changePassword,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: Text(
                      'MODIFIER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  void validateFields() {
    setState(() {
      oldPasswordError = oldPasswordController.text.isEmpty
          ? "Veuillez entrer votre ancien mot de passe."
          : null;
      newPasswordError = newPasswordController.text.isEmpty
          ? "Veuillez entrer votre nouveau mot de passe."
          : null;
      confirmPasswordError = confirmPasswordController.text.isEmpty
          ? "Veuillez confirmer votre nouveau mot de passe."
          : null;

      if (newPasswordController.text != confirmPasswordController.text) {
        confirmPasswordError = "Les mots de passe ne correspondent pas.";
        passwordsMatch = false;
      } else {
        confirmPasswordError = null;
        passwordsMatch = true;
      }
    });
  }

  Future<void> changePassword() async {
    if (oldPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        !passwordsMatch) {
      validateFields();
      return;
    }

    final String oldPassword = oldPasswordController.text;
    final String newPassword = newPasswordController.text;
    final String confirmPassword = confirmPasswordController.text;

    var response = await http.post(
      Uri.parse(Strings.apiURL + 'change_password.php'),
      body: {
        'userId': userId!,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Le mot de passe a été modifié avec succès."),
          backgroundColor: Colors.green,
        ));
        oldPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Erreur lors du changement de mot de passe. Veuillez réessayer."),
          backgroundColor: Colors.red,
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Erreur de communication avec le serveur. Veuillez réessayer."),
        backgroundColor: Colors.red,
      ));
    }
  }
}
