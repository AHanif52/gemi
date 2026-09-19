import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/database.dart' show Kantong;
import '../app/format.dart';
import '../app/theme.dart';
import '../kantong/kantong_controller.dart';
import 'baris_gemi.dart';

/// Sheet pilih kantong. Kembalikan id yang dipilih, null kalau ditutup.
Future<int?> pilihKantong(BuildContext context, {required String judul}) {
  final c = context.read<KantongController>();
  return showModalBottomSheet<int>(
    context: context,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          Text(judul, style: Theme.of(ctx).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final k in c.daftar)
            BarisGemi(judul: k.name, sub: k.type.label, nominal: fmtRupiah(c.saldo(k)), onTap: () => Navigator.pop(ctx, k.id)),
        ],
      ),
    ),
  );
}

/// Baris "label · nilai ›" yang membuka pilihan (tokens .pick).
class BarisPilih extends StatelessWidget {
  const BarisPilih({super.key, required this.label, required this.nilai, required this.onTap});
  final String label, nilai;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: g.ink2))),
            Text(nilai),
            const SizedBox(width: 12),
            Text('›', style: TextStyle(color: g.ink3)),
          ],
        ),
      ),
    );
  }
}

/// Nama kantong dari id, "?" kalau tidak ada.
String namaKantong(BuildContext context, int? id) =>
    context.read<KantongController>().daftar.where((k) => k.id == id).map((k) => k.name).firstOrNull ?? '?';

Kantong? kantongById(BuildContext context, int? id) => context.read<KantongController>().daftar.where((k) => k.id == id).firstOrNull;
