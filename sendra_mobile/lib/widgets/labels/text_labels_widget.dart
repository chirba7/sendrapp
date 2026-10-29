import 'package:flutter/material.dart';
import 'package:walletium/utils/dimsensions.dart';

// ignore: must_be_immutable
class TextLabelsWidget extends StatelessWidget {
  const TextLabelsWidget(
      {Key? key,
      required this.textLabels,
      required this.textColor,
      this.margin = 0.5})
      : super(key: key);

  final String textLabels;
  final Color textColor;
  final double margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(Dimensions.marginSize * margin),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              textLabels,
              style: TextStyle(
                  color: textColor, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          )
        ],
      ),
    );
  }
}
