import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/size.dart';
import 'package:walletium/utils/strings.dart';
import '../../widgets/others/back_button_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String fullName = '';
  String phone = '';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.primaryBackgroundColor,
      appBar: AppBar(
        backgroundColor: CustomColor.primaryColor,
        iconTheme: const IconThemeData(color: CustomColor.whiteColor),
        title: const Text(Strings.profile),
        elevation: 0,
        leading: const BackButtonWidget(
          backButtonImage: Strings.backButtonWhite,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 20.h,
              ),
              _profilePicture(context),
              SizedBox(
                height: 20.h,
              ),
              _usernameAndUserId(context),
              SizedBox(
                height: 40.h,
              ),
              _containerWidget(context),
            ],
          ),
        ),
      ),
    );
  }

  Container _profilePicture(BuildContext context) {
    return Container(
      width: 100.h,
      height: 100.h,
      decoration: BoxDecoration(
        color: CustomColor.textColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.account_circle_rounded,
        color: CustomColor.whiteColor,
        size: 80,
      ),
    );
  }

  Column _usernameAndUserId(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          fullName,
          style: CustomStyler.profileNameStyle,
        ),
        Text(
          phone,
          style: TextStyle(color: CustomColor.textColor, fontSize: 16.sp),
        ),
      ],
    );
  }

  Column _containerWidget(BuildContext context) {
    return Column(
      children: [
        _optionCard(context, Icons.key, Strings.changePassword, () {
          Get.toNamed(Routes.changePasswordScreen);
        }),
      ],
    );
  }

  InkWell _optionCard(
      BuildContext context, IconData icon, String name, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(15.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: CustomColor.textColor,
                    size: 30.sp,
                  ),
                  SizedBox(
                    width: 20.w,
                  ),
                  Text(
                    name,
                    style: CustomStyler.editProfileStyle,
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward_ios_sharp,
                color: CustomColor.textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
