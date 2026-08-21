import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DepositController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final paymentMethodController = TextEditingController();
  final titreController = TextEditingController();
  // final countryController = TextEditingController();
  // final cityController = TextEditingController();
  // final addressController = TextEditingController();
  // final zipCodeController = TextEditingController();
  // final emailController = TextEditingController();
  // final phoneNUmberController = TextEditingController();
  var carImagePath = ''.obs;

  void setCarImageImagePath(String path) {
    carImagePath.value = path;
  }
// @override
// void dispose() {
//   Get.delete<SignInController>();
//   super.dispose();
// }
}
