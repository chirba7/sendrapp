import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as Img; // Import the image package
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:walletium/controller/deposit_controller.dart';
import 'package:walletium/controller/input_image_controller.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';

// ignore: must_be_immutable
class InputImageWidget extends StatelessWidget {
  InputImageWidget({Key? key}) : super(key: key);
  final _controller = Get.put(InputImageController());
  final _controller_deposit = Get.put(DepositController());


  File? pickedFile;

  ImagePicker imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => Container(
          width: 100.w,
          height: 150.h,
          margin: EdgeInsets.all(Dimensions.marginSize * 0.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CustomColor.inputBackgroundColor,
            image: DecorationImage(
              image: _controller.carImagePath.value.isNotEmpty
                  ? FileImage(File(_controller.carImagePath.value))
              as ImageProvider
                  : const AssetImage(Strings.carPlaceHolder),
              // fit: BoxFit.cover,
            ),
          ),
            child: Container(
              alignment: Alignment.bottomCenter,
              padding: EdgeInsets.all(Dimensions.defaultPaddingSize * 0.3),
              child: Material(
                color: Colors.transparent, // Couleur de fond transparente pour que la forme ronde soit visible
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => _bottomSheet(context),
                    );
                  },
                  customBorder: CircleBorder(), // Forme ronde autour de l'icône
                  child: Container(
                    padding: EdgeInsets.all(12), // Ajustez la taille du padding selon votre préférence
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, // Forme ronde
                      color: Colors.grey.withOpacity(0.3), // Couleur de fond de la forme ronde
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Container _bottomSheet(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120.h,
      margin: EdgeInsets.all(Dimensions.marginSize * 0.5),
      child: Row(
        children: [
          Expanded( // Utiliser Expanded pour obtenir un espace égal à gauche
            child: _buildOptionButton(
              icon: Icons.image,
              text: 'Galerie',
              onPressed: () {
                takeCarPhoto(context, ImageSource.gallery);
              },
            ),
          ),
          Expanded( // Utiliser Expanded pour obtenir un espace égal à droite
            child: _buildOptionButton(
              icon: Icons.camera,
              text: 'Appareil photo',
              onPressed: () {
                takeCarPhoto(context, ImageSource.camera);
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildOptionButton({required IconData icon, required String text, required VoidCallback onPressed}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withOpacity(0.3),
            ),
            padding: EdgeInsets.all(10.w), // Réduire la taille du padding pour réduire la taille de la forme ronde
            child: Icon(
              icon,
              color: Colors.black,
              size: 50.sp,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          text,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }





  Future<void> takePhoto(ImageSource source) async {
    final pickedImage =
    await imagePicker.pickImage(source: source, imageQuality: 100);
    if (pickedFile != null) {
      pickedFile = File(pickedImage!.path);
      _controller.setCampaignImagePath(pickedFile!.path);
      //Navigator.of(Get.overlayContext!).pop(); // Close the bottom sheet
    }
  }

  Future<void> takeCarPhoto(BuildContext context, ImageSource source) async {
    final pickedImage =
    await imagePicker.pickImage(source: source, imageQuality: 100);
    if (pickedImage != null) {
      final String imagePath = pickedImage.path;
      _controller.setCarImageImagePath(imagePath);
      _controller_deposit.setCarImageImagePath(imagePath);
      Navigator.of(context).pop(); // Close the bottom sheet
    }
  }
}
