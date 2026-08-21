import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walletium/utils/custom_color.dart';
import 'package:walletium/utils/dimsensions.dart';
import 'package:walletium/utils/strings.dart';
import 'package:walletium/widgets/others/back_button_widget.dart';

class TransactionsHistoryScreen extends StatefulWidget {
  const TransactionsHistoryScreen({Key? key}) : super(key: key);

  @override
  _TransactionsHistoryScreenState createState() =>
      _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends State<TransactionsHistoryScreen> {
  List<dynamic> transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    getUserData();
  }

  Future<void> getUserData() async {}

  Future<void> _fetchData() async {
    List<dynamic> fetchedSignalements = await fetchSignalements();

    setState(() {
      transactions = fetchedSignalements;
    });
  }

  Future<List<dynamic>> fetchSignalements() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? 'No name';

    final response = await http.get(
      Uri.parse(Strings.apiURI + 'voirSignalements'),
      headers: <String, String>{
        "Content-Type": "application/json",
        'Authorization': 'Bearer ' + token,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Erreur lors de la récupération des signalements');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.myTransactionsHistory,
          style: TextStyle(color: CustomColor.whiteColor),
        ),
        leading: const BackButtonWidget(
          backButtonImage: Strings.backButtonWhite,
        ),
        backgroundColor: CustomColor.primaryColor,
        elevation: 0,
      ),
      body: _bodyWidget(context, transactions),
    );
  }

  Widget _bodyWidget(BuildContext context, List<dynamic> transactions) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Scrollbar(
        //showTrackOnHover: true,
        thickness: 6,
        radius: Radius.circular(3),
        child: ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (BuildContext context, int index) {
            final transaction = transactions[index];
            final titre = transaction['titre'] ?? 'Unknown';
            final date = transaction['formatted_date'] ?? 'Unknown';
            final imageUrl = transaction['image_url'] ?? 'Unknown';
            final commune = transaction['commune'] ?? 'Inconnue';

            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/depositMoneyDetailsScreen',
                  arguments: transaction['signalementId'],
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.network(
                          imageUrl,
                          height: 90.h,
                          width: 90.w,
                          fit: BoxFit.fill,
                        ),
                      ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              titre,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              commune,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            );
          },
        ),
      ),
    );
  }
}
