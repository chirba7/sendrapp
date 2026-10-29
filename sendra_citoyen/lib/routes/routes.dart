import 'package:get/get.dart';
import 'package:walletium/binding/splash_binding.dart';
import 'package:walletium/views/screens/about_us_screen.dart';
import 'package:walletium/views/screens/change_password_screen.dart';
import 'package:walletium/views/screens/deposit_money_details_screen.dart';
import 'package:walletium/views/screens/deposit_screen.dart';
import 'package:walletium/views/screens/edit_profile_screen.dart';
import 'package:walletium/views/screens/otp_verification_screen.dart';
import 'package:walletium/views/screens/phone_verification_screen.dart';
import 'package:walletium/views/screens/reset_password_congratulations_screen.dart';
import 'package:walletium/views/screens/reset_password_screen.dart';
import 'package:walletium/views/screens/sign_in_screen.dart';
import 'package:walletium/views/screens/sign_up_congratulations_screen.dart';
import 'package:walletium/views/screens/sign_up_screen.dart';
import 'package:walletium/views/screens/splash_screen.dart';
import 'package:walletium/views/screens/welcome_screen.dart';
import 'package:walletium/widgets/others/bottom_navigation_widget.dart';

import '../views/screens/profile_screen.dart';
import '../views/screens/signup_final.dart';

class Routes {
  static const String splashScreen = '/splashScreen';
  static const String welcomeScreen = '/welcomeScreen';
  static const String signInScreen = '/signInScreen';
  static const String signUpScreen = '/signUpScreen';
  static const String signUpFinalScreen = '/signUpFinalScreen';

  static const String otpVerificationScreen = '/otpVerificationScreen';
  static const String phoneVerificationScreen = '/phoneVerificationScreen';
  static const String resetPasswordScreen = '/resetPasswordScreen';
  static const String resetPasswordCongratulationsScreen =
      '/resetPasswordCongratulationsScreen';
  static const String signUpCongratulationsScreen =
      '/signUpCongratulationsScreen';
  static const String bottomNavigationScreen = '/bottomNavigationScreen';
  static const String changePasswordScreen = '/changePasswordScreen';
  static const String editProfileScreen = '/editProfileScreen';
  static const String depositScreen = '/depositScreen';
  static const String depositMoneyDetailsScreen = '/depositMoneyDetailsScreen';
  static const String aboutUsScreen = '/aboutUsScreen';
  static const String profileScreen = '/profileScreen';

  static final list = [
    GetPage(
      name: splashScreen,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: welcomeScreen,
      page: () => const WelcomeScreen(),
    ),
    GetPage(
      name: signInScreen,
      page: () => const SignInScreen(),
    ),
    GetPage(
      name: otpVerificationScreen,
      page: () => OtpVerificationScreen(),
    ),
    GetPage(
      name: resetPasswordScreen,
      page: () => ResetPasswordScreen(),
    ),
    GetPage(
      name: resetPasswordCongratulationsScreen,
      page: () => const ResetPasswordCongratulationsScreen(),
    ),
    GetPage(
      name: signUpScreen,
      page: () => const SignUpScreen(),
    ),
    GetPage(
      name: signUpFinalScreen,
      page: () => const SignUpFinalScreen(),
    ),
    GetPage(
      name: phoneVerificationScreen,
      page: () => const PhoneVerificationScreen(),
    ),
    GetPage(
      name: signUpCongratulationsScreen,
      page: () => const SignUpCongratulationsScreen(),
    ),
    GetPage(
      name: bottomNavigationScreen,
      page: () => const BottomNavigationWidget(),
    ),
    GetPage(
      name: changePasswordScreen,
      page: () => const ChangePasswordScreen(),
    ),
    GetPage(
      name: editProfileScreen,
      page: () => const EditProfileScreen(),
    ),
    GetPage(
      name: profileScreen,
      page: () => const ProfileScreen(),
    ),
    GetPage(
      name: depositScreen,
      page: () => const DepositScreen(),
    ),
    GetPage(
      name: depositMoneyDetailsScreen,
      page: () => const DepositMoneyDetailsScreen(),
    ),
    GetPage(
      name: aboutUsScreen,
      page: () => const AboutUsScreen(),
    ),
  ];
}
