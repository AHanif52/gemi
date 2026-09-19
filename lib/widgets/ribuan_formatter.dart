import 'package:flutter/services.dart';

import '../app/format.dart';

/// Sisipkan titik ribuan saat mengetik nominal; nilai mentah diambil lewat [parseRupiah].
class RibuanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final s = fmtRupiah(parseRupiah(newValue.text));
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}
