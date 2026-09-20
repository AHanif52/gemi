import 'package:flutter/material.dart';

import '../app/theme.dart';

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
    final surface2 = context.gemi.surface2;
    // Column/Row, bukan GridView: butuh intrinsic height untuk KolomIsiLayar.
    // Lebar maks 420 supaya di landscape/tablet tombol tidak raksasa.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            for (var r = 0; r < tombol.length; r += 3)
              Padding(
                padding: EdgeInsets.only(top: r == 0 ? 0 : 8),
                child: Row(
                  children: [
                    for (var i = r; i < r + 3; i++) ...[
                      if (i > r) const SizedBox(width: 8),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 2.1,
                          child: tombol[i].isEmpty
                              ? const SizedBox()
                              : Material(
                                  color: surface2,
                                  borderRadius: BorderRadius.circular(6),
                                  child: InkWell(
                                    key: Key('$keyPrefix.${tombol[i]}'),
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => onKetik(tombol[i]),
                                    child: Center(
                                      child: Text(
                                        tombol[i],
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
