import 'package:get/get.dart';
import 'package:walletium/binding/splash_binding.dart';
import 'package:walletium/views/screens/about_us_screen.dart';
import 'package:walletium/views/screens/change_password_screen.dart';
import 'package:walletium/views/screens/deposit_history_screen.dart';
import 'package:walletium/views/screens/deposit_money_details_screen.dart';
import 'package:walletium/views/screens/deposit_money_review_screen.dart';
import 'package:walletium/views/screens/deposit_money_success_screen.dart';
import 'package:walletium/views/screens/deposit_screen.dart';
import 'package:walletium/views/screens/edit_profile_screen.dart';
import 'package:walletium/views/screens/kyc_screen.dart';
import 'package:walletium/views/screens/onboard_screen.dart';
import 'package:walletium/views/screens/otp_verification_screen.dart';
import 'package:walletium/views/screens/phone_verification_screen.dart';
import 'package:walletium/views/screens/request_money_review_screen.dart';
import 'package:walletium/views/screens/request_money_screen.dart';
import 'package:walletium/views/screens/request_money_success_screen.dart';
import 'package:walletium/views/screens/reset_password_congratulations_screen.dart';
import 'package:walletium/views/screens/reset_password_screen.dart';
import 'package:walletium/views/screens/send_money_details_screen.dart';
import 'package:walletium/views/screens/send_money_screen.dart';
import 'package:walletium/views/screens/send_money_success_screen.dart';
import 'package:walletium/views/screens/sign_in_screen.dart';
import 'package:walletium/views/screens/sign_up_congratulations_screen.dart';
import 'package:walletium/views/screens/sign_up_screen.dart';
import 'package:walletium/views/screens/splash_screen.dart';
import 'package:walletium/views/screens/transactions_history_screen.dart';
import 'package:walletium/views/screens/transfer_history_screen.dart';
import 'package:walletium/views/screens/welcome_screen.dart';
import 'package:walletium/views/screens/withdraw_histrory_screen.dart';
import 'package:walletium/views/screens/withdraw_money_details_screen.dart';
import 'package:walletium/views/screens/withdraw_money_preview_screen.dart';
import 'package:walletium/views/screens/withdraw_money_success_screen.dart';
import 'package:walletium/views/screens/withdraw_screen.dart';
import 'package:walletium/widgets/others/bottom_navigation_widget.dart';

import '../views/screens/carto.dart';
import '../views/screens/profile_screen.dart';
import '../views/screens/signup_final.dart';

class Routes {
  static const String splashScreen = '/splashScreen';
  static const String onboardScreen = '/onboardScreen';
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
  static const String withdrawScreen = '/withdrawScreen';
  static const String sendMoneyScreen = '/sendMoneyScreen';
  static const String sendMoneyDetailsScreen = '/sendMoneyDetailsScreen';
  static const String sendMoneySuccessScreen = '/sendMoneySuccessScreen';
  static const String requestMoneyScreen = '/requestMoneyScreen';
  static const String requestMoneyReviewScreen = '/requestMoneyReviewScreen';
  static const String requestMoneySuccessScreen = '/requestMoneySuccessScreen';
  static const String depositMoneyDetailsScreen = '/depositMoneyDetailsScreen';
  static const String depositMoneySuccessScreen = '/depositMoneySuccessScreen';
  static const String depositMoneyReviewScreen = '/depositMoneyReviewScreen';
  static const String withdrawMoneyDetailsScreen =
      '/withdrawMoneyDetailsScreen';
  static const String withdrawMoneyReviewScreen = '/withdrawMoneyReviewScreen';
  static const String withdrawMoneySuccessScreen =
      '/withdrawMoneySuccessScreen';
  static const String transactionsHistoryScreen = '/transactionsHistoryScreen';
  static const String transferHistoryScreen = '/transferHistoryScreen';
  static const String depositHistoryScreen = '/depositHistoryScreen';
  static const String withdrawHistoryScreen = '/withdrawHistoryScreen';
  static const String kycScreen = '/kycScreen';
  static const String aboutUsScreen = '/aboutUsScreen';
  static const String cartoScreen = '/cartoScreen';
  static const String profileScreen = '/profileScreen';

  static var list = [
    GetPage(
      name: splashScreen,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: onboardScreen,
      page: () => OnboardScreen(),
    ),
    GetPage(
      name: welcomeScreen,
      page: () => const WelcomeScreen(),
    ),
    GetPage(
      name: signInScreen,
      page: () => SignInScreen(),
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
      page: () => SignUpScreen(),
    ),
    GetPage(
      name: signUpFinalScreen,
      page: () => SignUpFinalScreen(),
    ),
    GetPage(
      name: phoneVerificationScreen,
      page: () => PhoneVerificationScreen(),
    ),
    GetPage(
      name: signUpCongratulationsScreen,
      page: () => const SignUpCongratulationsScreen(),
    ),
    GetPage(
      name: bottomNavigationScreen,
      page: () => BottomNavigationWidget(),
    ),
    GetPage(
      name: changePasswordScreen,
      page: () => ChangePasswordScreen(),
    ),
    GetPage(
      name: editProfileScreen,
      page: () => EditProfileScreen(),
    ),
    GetPage(
      name: profileScreen,
      page: () => ProfileScreen(),
    ),
    GetPage(
      name: depositScreen,
      page: () => DepositScreen(),
    ),
    GetPage(
      name: withdrawScreen,
      page: () => WithdrawScreen(),
    ),
    GetPage(
      name: sendMoneyScreen,
      page: () => SendMoneyScreen(),
    ),
    GetPage(
      name: requestMoneyScreen,
      page: () => RequestMoneyScreen(),
    ),
    GetPage(
      name: sendMoneyDetailsScreen,
      page: () => SendMoneyDetailsScreen(),
    ),
    GetPage(
      name: sendMoneySuccessScreen,
      page: () => const SendMoneySuccessScreen(),
    ),
    GetPage(
      name: requestMoneyReviewScreen,
      page: () => const RequestMoneyReviewScreen(),
    ),
    GetPage(
      name: requestMoneySuccessScreen,
      page: () => const RequestMoneySuccessScreen(),
    ),
    GetPage(
      name: depositMoneyDetailsScreen,
      page: () => DepositMoneyDetailsScreen(),
    ),
    GetPage(
      name: depositMoneySuccessScreen,
      page: () => const DepositMoneySuccessScreen(),
    ),
    GetPage(
      name: depositMoneyReviewScreen,
      page: () => const DepositMoneyReviewScreen(),
    ),
    GetPage(
      name: withdrawMoneyDetailsScreen,
      page: () => WithdrawMoneyDetailsScreen(),
    ),
    GetPage(
      name: withdrawMoneyReviewScreen,
      page: () => const WithdrawMoneyPreviewScreen(),
    ),
    GetPage(
      name: withdrawMoneySuccessScreen,
      page: () => const WithdrawMoneySuccessScreen(),
    ),
    GetPage(
      name: transactionsHistoryScreen,
      page: () => const TransactionsHistoryScreen(),
    ),
    GetPage(
      name: transferHistoryScreen,
      page: () => const TransferHistoryScreen(),
    ),
    GetPage(
      name: depositHistoryScreen,
      page: () => const DepositHistoryScreen(),
    ),
    GetPage(
      name: withdrawHistoryScreen,
      page: () => const WithdrawHistoryScreen(),
    ),
    GetPage(
      name: kycScreen,
      page: () => const KycScreen(),
    ),
    GetPage(
      name: aboutUsScreen,
      page: () => const AboutUsScreen(),
    ),
    /*
    GetPage(
      name: cartoScreen,
      page: () => const CartoScreen(),
    ),

     */
  ];
}
