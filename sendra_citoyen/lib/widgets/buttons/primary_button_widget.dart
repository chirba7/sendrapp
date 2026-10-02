import 'package:flutter/material.dart';

import '../../utils/dimsensions.dart';

class PrimaryButtonWidget extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final bool isLoading; // Added isLoading parameter

  const PrimaryButtonWidget({
    Key? key,
    required this.title,
    required this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Dimensions.buttonHeight,
      margin: EdgeInsets.only(
        left: Dimensions.marginSize * 0.5,
        right: Dimensions.marginSize * 0.5,
        top: Dimensions.marginSize,
      ),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: Dimensions.largeTextSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
        style: TextButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
            side: BorderSide(
              width: 1,
              color: borderColor,
            ),
          ),
        ),
      ),
    );
  }
}
