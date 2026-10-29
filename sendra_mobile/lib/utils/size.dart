import 'package:flutter/material.dart';

Widget addVerticalSpace(double height) {
  return SizedBox(
    height: height,
  );
}

Widget addHorizontalSpace(double width) {
  return SizedBox(
    width: width,
  );
}

MainAxisAlignment mainStart = MainAxisAlignment.start;
MainAxisAlignment mainCenter = MainAxisAlignment.center;

CrossAxisAlignment crossStart = CrossAxisAlignment.start;
CrossAxisAlignment crossCenter = CrossAxisAlignment.center;
