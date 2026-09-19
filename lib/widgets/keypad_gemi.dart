import 'package:flutter/material.dart';

/// Keypad penuh 3x4 (prototipe `.kbd`). Tombol kosong ('') tidak digambar.
/// Dipakai form nominal (000 di kiri bawah) dan layar PIN (kiri bawah kosong).
class KeypadGemi extends StatelessWidget {
  const KeypadGemi({
    super.key,
    required this.onKetik,
    required this.keyPrefix,
    this.tombol = nominal,
  });

  final ValueChanged<String> onKetik;
  final String keyPrefix; // Key('$keyPrefix.$tombol') untuk test/agen
  final List<String> tombol;

  static const nominal = [
    '1', '2', '3', //
    '4', '5', '6',
    '7', '8', '9',
    '000', '0', '⌫',
  ];
  static const pin = [
    '1', '2', '3', //
    '4', '5', '6',
    '7', '8', '9',
    '', '0', '⌫',
  ];

  @override
  Widget build(BuildContext context) {
    final surface2 = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF222925)
        : const Color(0xFFF6F7F5);
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.1,
      children: [
        for (final k in tombol)
          if (k.isEmpty)
            const SizedBox()
          else
            Material(
              color: surface2,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                key: Key('$keyPrefix.$k'),
                borderRadius: BorderRadius.circular(6),
                onTap: () => onKetik(k),
                child: Center(
                  child: Text(k, style: const TextStyle(fontSize: 22)),
                ),
              ),
            ),
      ],
    );
  }
}
