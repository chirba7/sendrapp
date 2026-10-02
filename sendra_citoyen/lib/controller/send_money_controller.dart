import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SendMoneyController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final youSendController = TextEditingController();
  final recipientGetsController = TextEditingController();


// @override
// void dispose() {
//   Get.delete<SignInController>();
//   super.dispose();
// }
}