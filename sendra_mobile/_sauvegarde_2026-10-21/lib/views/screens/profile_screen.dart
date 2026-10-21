import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/routes/routes.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
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
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString('fullName') ?? 'Nom non renseigné';
      phone = prefs.getString('phone') ?? 'Téléphone non renseigné';
      photoUrl = prefs.getString('profilePhotoUrl');
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF074C32), Color(0xFF15965C)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(children: [
                _profilePicture(context),
                const SizedBox(height: 14),
                Text(fullName, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(phone, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Get.toNamed(Routes.editProfileScreen);
                    await getUserData();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier mes informations'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70)),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Align(alignment: Alignment.centerLeft,
              child: Text('Mon compte', style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 10),
            _containerWidget(context),
          ]),
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
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(child: Image.network(photoUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.account_circle_rounded,
                  color: CustomColor.whiteColor, size: 80)))
          : const Icon(Icons.account_circle_rounded,
              color: CustomColor.whiteColor, size: 80),
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
              Expanded(child: Row(
                children: [
                  Icon(
                    icon,
                    color: CustomColor.textColor,
                    size: 30.sp,
                  ),
                  SizedBox(
                    width: 20.w,
                  ),
                  Flexible(child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: CustomStyler.editProfileStyle,
                  )),
                ],
              )),
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
