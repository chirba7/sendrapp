import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditProfileController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final countryController = TextEditingController();
  final cityController = TextEditingController();
  final addressController = TextEditingController();
  final zipCodeController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNUmberController = TextEditingController();


// @override
// void dispose() {
//   Get.delete<SignInController>();
//   super.dispose();
// }
}
