import 'package:flutter/material.dart';

String taxMoneyInput(int cents) =>
    (cents / 100).toStringAsFixed(2).replaceAll('.', ',');

int parseTaxMoney(String text, {bool signed = false}) {
  final value = text.trim();
  if (value.isEmpty) {
    throw const FormatException('Informe o valor, inclusive quando for zero.');
  }
  final pattern = signed
      ? r'^-?(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d{1,2})?$'
      : r'^(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d{1,2})?$';
  if (!RegExp(pattern).hasMatch(value)) {
    throw const FormatException('Use reais no formato 1.234,56.');
  }
  final normalized = value.replaceAll('.', '');
  final parts = normalized.replaceAll('-', '').split(',');
  final cents =
      int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
  if (cents > 10000000000000) {
    throw const FormatException('Valor acima do limite.');
  }
  return normalized.startsWith('-') ? -cents : cents;
}

class TaxMoneyField extends StatelessWidget {
  const TaxMoneyField({
    required this.label,
    required this.controller,
    this.signed = false,
    super.key,
  });
  final String label;
  final TextEditingController controller;
  final bool signed;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label, prefixText: 'R\$ '),
    keyboardType: TextInputType.numberWithOptions(
      decimal: true,
      signed: signed,
    ),
    validator: (value) {
      try {
        parseTaxMoney(value ?? '', signed: signed);
        return null;
      } on FormatException catch (e) {
        return e.message;
      }
    },
  );
}
