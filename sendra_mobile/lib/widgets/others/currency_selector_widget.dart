import 'package:country_currency_pickers/country_pickers.dart';
import 'package:country_currency_pickers/currency_picker_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:country_currency_pickers/country.dart';
import 'package:country_currency_pickers/utils/utils.dart';
import 'package:walletium/utils/dimsensions.dart';

class CurrencySelectorWidget extends StatefulWidget {
  const CurrencySelectorWidget({Key? key}) : super(key: key);

  @override
  State<CurrencySelectorWidget> createState() => _CurrencySelectorWidgetState();
}

class _CurrencySelectorWidgetState extends State<CurrencySelectorWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: const Color(0xFFE9EDEE),
          borderRadius: BorderRadius.circular(Dimensions.radius * 1)),
      child: ListTile(title: _buildCurrencyPickerDropdown(false)),
    );
  }

  Row _buildCurrencyPickerDropdown(bool filtered) => Row(
        children: <Widget>[
          CurrencyPickerDropdown(
            initialValue: 'BDT',
            itemBuilder: _buildCurrencyDropdownItem,
            itemFilter: filtered
                ? (c) =>
                    ['BDT', 'USD', 'CHF', 'EUR', 'INR'].contains(c.currencyCode)
                : null,
            onValuePicked: (Country? country) {
              // ignore: avoid_print
              print('${country?.name}');
            },
          ),
        ],
      );

  Widget _buildCurrencyDropdownItem(Country country) => Row(
    children: <Widget>[
      CountryPickerUtils.getDefaultFlagImage(country),
      const SizedBox(
        width: 8.0,
      ),
      Text('${country.currencyCode}'),
    ],
  );
}
