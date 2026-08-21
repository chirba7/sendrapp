import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/controller/edit_profile_controller.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/buttons/primary_button_widget.dart';
import 'package:walletium/widgets/inputs/input_text_field.dart';
import 'package:walletium/widgets/labels/text_labels_widget.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';
import 'package:walletium/widgets/others/input_picture_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _controller = Get.put(EditProfileController());
  late String fullName;
  late String phone;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString('fullName') ?? 'No name';
      phone = prefs.getString('phone') ?? 'No phone';
    });

    // Use the retrieved data wherever needed in the app
    print('Full Name: $fullName');
    print('Phone: $phone');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.editProfile,
          style: TextStyle(color: CustomColor.whiteColor),
        ),
        leading: const BackButtonWidget(
          backButtonImage: Strings.backButtonWhite,
        ),
        backgroundColor: CustomColor.primaryColor,
        elevation: 0,
      ),
      body: _bodyWidget(context),
    );
  }

  ListView _bodyWidget(BuildContext context) {
    return ListView(
      children: [
        //_profilePictureWidget(context),
        _inputWidgets(context),
        _continueButtonWidget(context),
        addVerticalSpace(20.h),
      ],
    );
  }

  InputImageWidget _profilePictureWidget(BuildContext context) {
    return InputImageWidget();
  }

  Form _inputWidgets(BuildContext context) {
    return Form(
      key: _controller.formKey,
      child: Column(
        children: [
          TextLabelsWidget(
            textLabels: fullName,
            textColor: CustomColor.textColor,
          ),
          Container(
            margin:
                EdgeInsets.symmetric(horizontal: Dimensions.marginSize * 0.5),
            child: InputTextField(
              controller: _controller.nameController,
              hintText: 'Modifier le nom',
              backgroundColor: Colors.transparent,
              hintTextColor: CustomColor.gray,
              borderColor: CustomColor.gray,
            ),
          ),
        ],
      ),
    );
  }

  PrimaryButtonWidget _continueButtonWidget(BuildContext context) {
    return PrimaryButtonWidget(
      title: Strings.conTinue,
      onPressed: () {
        Get.back();
      },
      borderColor: CustomColor.primaryColor,
      backgroundColor: CustomColor.primaryColor,
      textColor: CustomColor.whiteColor,
    );
  }

  // Add other methods for widgets like selectCountryWidget, selectCityWidget, etc.
}
