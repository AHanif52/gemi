import 'package:flutter/material.dart';

/// Column setinggi layar (Spacer tetap mendorong tombol ke bawah), tapi bisa
/// di-scroll saat ruang kurang: keyboard muncul, font besar, atau landscape.
class KolomIsiLayar extends StatelessWidget {
  const KolomIsiLayar({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
