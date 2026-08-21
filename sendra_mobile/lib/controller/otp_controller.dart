import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtpController extends GetxController {
  TextEditingController otpController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    otpController = TextEditingController();
  }

  @override
  void onClose() {
    otpController
        .dispose(); // Dispose the TextEditingController when the controller is closed.
    super.onClose();
  }
}
