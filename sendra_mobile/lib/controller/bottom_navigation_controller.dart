import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:walletium/utils/strings.dart';

class BottomNavigationController extends GetxController {
  var currentIndex = 0.obs;

  int getIndex() => currentIndex.value;

  dynamic setIndex(val) => currentIndex.value = val;

  static const navigationBarItems = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(FontAwesomeIcons.car),
      label: Strings.home,
    ),

    BottomNavigationBarItem(
      icon: Icon(
        FontAwesomeIcons.mapLocation,
      ),
      label: Strings.cartoItem,
    ),
  ];
}
