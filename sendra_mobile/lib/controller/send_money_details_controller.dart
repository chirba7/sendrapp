import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SendMoneyDetailsController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailContainer = TextEditingController();
  final paymentDescriptionController = TextEditingController();


// @override
// void dispose() {
//   Get.delete<SignInController>();
//   super.dispose();
// }
}