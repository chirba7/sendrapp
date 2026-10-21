import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestMoneyController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final payerNameController = TextEditingController();
  final emailController = TextEditingController();
  final selectCountryController = TextEditingController();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final paymentDueBYController = TextEditingController();


// @override
// void dispose() {
//   Get.delete<SignInController>();
//   super.dispose();
// }
}