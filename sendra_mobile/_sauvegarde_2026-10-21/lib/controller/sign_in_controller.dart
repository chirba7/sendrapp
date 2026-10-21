import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignInController extends GetxController {
  final emailOrUserNameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();


  @override
  void dispose() {
    emailOrUserNameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
