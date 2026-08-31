import 'dart:convert';

import 'dart:io'; // Ajoutez cette ligne pour importer SocketException
import 'dart:async'; // Ajoutez cette ligne pour importer TimeoutException
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/sign_in_controller.dart';
import '../../routes/routes.dart';
import '../../utils/custom_color.dart';
import '../../utils/dimsensions.dart';
import '../../utils/session.dart';
import '../../utils/strings.dart';
import '../../widgets/buttons/primary_button_widget.dart';
import '../../widgets/inputs/input_text_field.dart';
import '../../widgets/labels/text_labels_widget.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _controller = Get.put(SignInController());
  final formKey = GlobalKey<FormState>();
  String _errorMessage = '';
  bool _obscureText = true;
  bool isLoading = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _bodyWidget(context),
    );
  }

  String _formatPhoneNumber(String text) {
    // Supprimer tous les espaces existants
    text = text.replaceAll(' ', '');

    // Si le texte a moins de 9 caractères, formatter par groupes de 2-3-2-2
    if (text.length <= 9) {
      String formatted = '';
      for (int i = 0; i < text.length; i++) {
        // Ajouter un espace après 2 chiffres
        if (i == 2) formatted += ' ';
        // Ajouter un espace après 5 chiffres
        if (i == 5) formatted += ' ';
        // Ajouter un espace après 7 chiffres
        if (i == 7) formatted += ' ';
        formatted += text[i];
      }
      return formatted;
    }
    return text.substring(0, 9); // Limiter à 9 chiffres
  }

  String _cleanPhoneNumber(String phone) {
    // Supprimer tous les espaces pour le traitement
    return phone.replaceAll(' ', '');
  }

  Future<void> saveUserData(String fullName, String phone, id, token, int? roleId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', fullName);
    await prefs.setString('phone', phone);
    await prefs.setString('userId', id);
    await prefs.setString('token', token);
    await Session.saveRoleId(roleId);
  }

  Future<void> _signIn() async {
    // Activer l'indicateur de chargement
    setState(() {
      isLoading = true;
    });

    String telephone = _cleanPhoneNumber(_controller.emailOrUserNameController.text);
    String password = _controller.passwordController.text;

    if (telephone.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez saisir le numéro de téléphone et le mot de passe.';
        isLoading = false; // Désactiver l'indicateur de chargement en cas d'erreur
      });
      return;
    }

    try {
      Map<String, String> requestBody = {
        'telephone': telephone,
        'password': password,
      };

      final response = await http.post(
        Uri.parse(Strings.apiURI + 'login'),
        body: requestBody,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        bool success = jsonResponse['success'];
        if (success) {
          String fullName = jsonResponse['fullName'].toString();
          String userId = jsonResponse['userId'].toString();
          String token = jsonResponse['token'].toString();
          int? roleId = jsonResponse['role_id'] is int
              ? jsonResponse['role_id']
              : int.tryParse(jsonResponse['role_id']?.toString() ?? '');

          await saveUserData(fullName, telephone, userId, token, roleId);

          // Désactiver l'indicateur de chargement avant la navigation
          setState(() {
            isLoading = false;
          });
          Get.offAllNamed(Routes.bottomNavigationScreen);
        } else {
          String errorMessage = jsonResponse['error'].toString();
          setState(() {
            _errorMessage = errorMessage;
            isLoading = false; // Désactiver l'indicateur de chargement
          });
        }
      } else if (response.statusCode == 401) {
        // Désactiver l'indicateur de chargement
        setState(() {
          isLoading = false;
        });
        showDialog(
          context: context,
          barrierColor: Colors.black54,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              backgroundColor: Colors.white,
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Identifiants invalides',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Les informations saisies sont incorrectes. Veuillez vérifier le numéro de téléphone et le mot de passe.',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Réessayer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        // Désactiver l'indicateur de chargement
        setState(() {
          isLoading = false;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Erreur',
                style: TextStyle(
                  color: CustomColor.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Une erreur s\'est produite lors de la demande. Veuillez réessayer plus tard.',
                    style: TextStyle(
                      color: CustomColor.textColor,
                    ),
                  ),
                ],
              ),
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
    } catch (error) {
      String errorMessage;
      if (error is SocketException) {
        errorMessage = 'Erreur de connexion réseau. Veuillez vérifier votre connexion internet.';
      } else if (error is TimeoutException) {
        errorMessage = 'La demande a expiré. Veuillez réessayer plus tard.';
      } else {
        errorMessage = 'Une erreur s\'est produite : $error';
      }
      setState(() {
        _errorMessage = errorMessage;
        isLoading = false; // Désactiver l'indicateur de chargement en cas d'erreur
      });
    }
  }

  Widget _bodyWidget(BuildContext context) {
    return Container(
      // Utiliser tout l'espace disponible sans fixer de dimensions
      constraints: BoxConstraints.expand(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.green.shade900,
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          // Utiliser EdgeInsets.symmetric avec MediaQuery pour un padding adaptif
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _backButton(context),
              _titleAndDesWidget(context),
              SizedBox(height: MediaQuery.of(context).size.height * 0.0),
              _inputWidgets(context),
              SizedBox(height: MediaQuery.of(context).size.height * 0.0),
              _signInButtonWidget(context),
              SizedBox(height: MediaQuery.of(context).size.height * 0.0),
              _forgotPasswordWidget(context),
              // Ajouter un espace relatif en bas pour s'assurer que tout est visible
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.all(Dimensions.marginSize * 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50), // Ajoute un espacement vertical
          Text(
            Strings.signIn,
            style: TextStyle(
              color: CustomColor.textColor,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  Widget _titleAndDesWidget(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize), // Ajustez la marge horizontale selon vos besoins
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/EPAVIE2.png',
            fit: BoxFit.contain,
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.9 * (3 / 4),
          ),
        ],
      ),
    );
  }

  Widget _inputWidgets(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextLabelsWidget(
            textLabels: Strings.phoneNumber,
            textColor: CustomColor.whiteColor,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: TextFormField(
              keyboardType: TextInputType.number,
              controller: _controller.emailOrUserNameController,
              inputFormatters: [
                LengthLimitingTextInputFormatter(12),  // 9 chiffres + 3 espaces
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), // Permet uniquement les chiffres et espaces
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre numéro de téléphone';
                }
                // Vérifier si le numéro (sans espaces) a exactement 9 chiffres
                String cleaned = _cleanPhoneNumber(value);
                if (cleaned.length != 9 || !RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
                  return 'Le numéro doit contenir exactement 9 chiffres';
                }
                return null;
              },
              onChanged: (value) {
                // Formatter le numéro pendant la saisie
                String formatted = _formatPhoneNumber(value);
                if (formatted != value) {
                  _controller.emailOrUserNameController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
              decoration: InputDecoration(
                hintText: 'XX XXX XX XX',
                hintStyle: TextStyle(color: CustomColor.gray),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: CustomColor.gray),
                ),
              ),
            ),
          ),
          TextLabelsWidget(
            textLabels: Strings.password,
            textColor: CustomColor.whiteColor,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: TextFormField(
              controller: _controller.passwordController,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Veuillez saisir votre mot de passe';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: Strings.password,
                hintStyle: TextStyle(color: CustomColor.gray),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: CustomColor.gray),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: CustomColor.gray,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText; // Basculer l'état du mot de passe
                    });
                  },
                ),
              ),
              obscureText: _obscureText, // L'état du mot de passe (visible ou caché)
            ),
          ),
        ],
      ),
    );
  }

  Widget _signInButtonWidget(BuildContext context) {
    return Column(
      children: [
        PrimaryButtonWidget(
          title: Strings.signIn,
          onPressed: () {
            if (formKey.currentState != null && formKey.currentState!.validate()) {
              _signIn();
            }
          },
          isLoading: isLoading, // Transmettre l'état de chargement au bouton
          borderColor: Color.fromARGB(255, 27, 27, 55),
          backgroundColor: CustomColor.textColor,
          textColor: CustomColor.whiteColor,
        ),
        Text(
          _errorMessage,
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _forgotPasswordWidget(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.only(top: 53.h),
      child: GestureDetector(
        onTap: () {
          _forgotPasswordScreen(context);
        },
        child: Text(
          Strings.forgotPassword,
          style: TextStyle(
            color: CustomColor.whiteColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future _forgotPasswordScreen(BuildContext context) {
    final forgotFormKey = GlobalKey<FormState>();
    var width = MediaQuery.of(context).size.width;
    return showDialog(
        context: context,
        builder: (_) => AlertDialog(
            backgroundColor: CustomColor.whiteColor,
            alignment: Alignment.center,
            insetPadding: EdgeInsets.all(Dimensions.defaultPaddingSize * 0.2),
            contentPadding: EdgeInsets.zero,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Builder(
              builder: (context) {
                return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: CustomColor.primaryBackgroundColor,
                    ),
                    padding: const EdgeInsets.all(10),
                    width: width * 0.9,
                    height: 500,
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 20.h),
                            Container(
                              decoration: const BoxDecoration(
                                color: CustomColor.primaryBackgroundColor,
                              ),
                              child: Image.asset(
                                Strings.forgotPassImage,
                                height: 100,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              Strings.forgotPasswordTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: CustomColor.textColor,
                                  fontSize: Dimensions.largeTextSize + 5,
                                  fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 20.h),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize),
                              width: double.infinity,
                              child: Text(
                                Strings.forgotPasswordDescription,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: CustomColor.textColor.withOpacity(0.6),
                                ),
                              ),
                            ),
                            TextLabelsWidget(
                              margin: 0.5,
                              textLabels: Strings.phoneNumber,
                              textColor: CustomColor.textColor,
                            ),
                            Form(
                              key: forgotFormKey,
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
                                child: InputTextField(
                                  hintText: Strings.enterPhoneNumber,
                                  hintTextColor: CustomColor.textColor,
                                  backgroundColor: CustomColor.whiteColor,
                                  controller: _controller.emailController,
                                  borderColor: CustomColor.gray,
                                ),
                              ),
                            ),
                            PrimaryButtonWidget(
                              title: Strings.conTinue,
                              onPressed: () {
                                Get.toNamed(Routes.otpVerificationScreen);
                              },
                              textColor: CustomColor.whiteColor,
                              backgroundColor: CustomColor.textColor,
                              borderColor: CustomColor.textColor,
                            ),
                          ],
                        ),
                        Positioned(
                            top: 5,
                            right: 5,
                            child: IconButton(
                              onPressed: () {
                                Get.back();
                              },
                              icon: Icon(
                                Icons.close,
                                color: CustomColor.gray,
                              ),
                            ))
                      ],
                    ));
              },
            )));
  }
}
