import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:walletium/controller/dropdown_controller.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/custom_style.dart';
import 'package:walletium/utils/dimsensions.dart';

class DropdownWidget extends StatelessWidget {
  DropdownWidget({Key? key}) : super(key: key);

  final _controller = Get.put(DropdownController());

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.defaultPaddingSize),
      child: DropdownButtonHideUnderline(
          child: Obx(() => DropdownButton(
            dropdownColor: CustomColor.whiteColor,
            icon: const Icon(
              Icons.arrow_drop_down,
              color: CustomColor.gray,
            ),
            isExpanded: true,
            style: CustomStyler.textStyler,
            value: _controller.selected.value,
            items: _controller.listItem.map((valueItem) {
              return DropdownMenuItem(
                value: valueItem,
                child: Text(
                    valueItem,
                    style: CustomStyler.paymentMethodTextStyle
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              _controller.setSelected(newValue.toString());
            },
          ),)
      ),
    );
  }
}

