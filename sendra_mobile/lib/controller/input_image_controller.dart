import 'package:get/get.dart';

class InputImageController extends GetxController {
  var isCampaignPicPathSet = false.obs;
  var campaignPicPath = ''.obs;
  var carImagePath = ''.obs;

  void setCampaignImagePath(String path) {
    campaignPicPath.value = path;
    isCampaignPicPathSet.value = true;
  }

  void setCarImageImagePath(String path) {
    carImagePath.value = path;
  }
}
