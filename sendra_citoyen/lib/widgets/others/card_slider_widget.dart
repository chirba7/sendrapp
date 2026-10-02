import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/strings.dart';

class CardSliderWidget extends StatefulWidget {
  CardSliderWidget({Key? key}) : super(key: key);

  @override
  State<CardSliderWidget> createState() => _CardSliderWidgetState();
}

class _CardSliderWidgetState extends State<CardSliderWidget> {
  int _current = 0;
  List<Map<String, dynamic>> signalements = [];

  @override
  void initState() {
    super.initState();
    fetchSignalementsData();
  }

  Future<void> fetchSignalementsData() async {
    final url = Strings.apiURL +
        'historique.php?action=getLatestSignalements'; // Replace with the actual API URL
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        setState(() {
          signalements = data.cast<Map<String, dynamic>>();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> imageSliders = signalements.map((signalement) {
      final imageUrl = signalement['image_url'];

      print('Image URL: $imageUrl'); // Print the imageUrl variable

      if (imageUrl != null && imageUrl is String) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
        );
      } else {
        // Return a placeholder widget if the image URL is null or not a valid string
        return Container(
          color: Colors.grey, // Placeholder color
          width: double.infinity,
          height: 240.h,
        );
      }
    }).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          CarouselSlider(
            items: imageSliders,
            options: CarouselOptions(
              height: 240.h,
              autoPlay: false,
              enlargeCenterPage: true,
              enableInfiniteScroll: true,
              autoPlayAnimationDuration: const Duration(milliseconds: 1000),
              viewportFraction: 0.77,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: signalements.map((signalement) {
              final index = signalements.indexOf(signalement);

              return Container(
                width: 10,
                height: 10,
                margin: EdgeInsets.symmetric(
                  horizontal: Dimensions.marginSize * 0.2,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _current == index
                      ? CustomColor.whiteColor
                      : const Color(0xff0c8035),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
