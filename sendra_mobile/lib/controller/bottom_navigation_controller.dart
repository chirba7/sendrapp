import 'package:get/get.dart';

class BottomNavigationController extends GetxController {
  var currentIndex = 0.obs;

  int getIndex() => currentIndex.value;

  dynamic setIndex(val) => currentIndex.value = val;
}
