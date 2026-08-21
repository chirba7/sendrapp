import 'package:get/get.dart';
import 'package:walletium/utils/strings.dart';

class DropdownController extends GetxController{

  final selected = Strings.paymentMethod.obs;

  void setSelected(String value){
    selected.value = value;
  }

  String country = Strings.paymentMethod;

  final List listItem = [
    Strings.paymentMethod,
    'Visa',
    'Mastercard',
    'paypal',
    'Skrill'
  ];




}