import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WithdrawMoneyDetailsController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final accountHolderNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final selectCountryController = TextEditingController();


// @override
// void dispose() {
//   Get.delete<SignInController>();
//   super.dispose();
// }
}