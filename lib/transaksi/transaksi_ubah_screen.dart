import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/database.dart' show Transaksi;
import '../app/format.dart';
import '../app/theme.dart';
import '../widgets/pilih_kantong.dart';
import '../widgets/ribuan_formatter.dart';
import 'transaksi_controller.dart';
import 'transaksi_model.dart';

/// /transaksi/ubah — ubah atau hapus satu transaksi (FR-02). Jenis tidak bisa diganti.
class TransaksiUbahScreen extends StatefulWidget {
  const TransaksiUbahScreen(this.baris, {super.key});
  final TransaksiBaris baris;

  @override
  State<TransaksiUbahScreen> createState() => _TransaksiUbahScreenState();
}

class _TransaksiUbahScreenState extends State<TransaksiUbahScreen> {
  late final _nominal = TextEditingController(text: fmtRupiah(t.amount));
  late final _catatan = TextEditingController(text: t.note ?? '');
  late int? _kategori = t.categoryId;
  late int _kantong = t.accountId;
  late int? _tujuan = t.toAccountId;
  late String _tanggal = t.date;

  Transaksi get t => widget.baris.t;
  bool get _transfer => t.type == JenisTransaksi.transfer;

  @override
  void dispose() {
    _nominal.dispose();
    _catatan.dispose();
    super.dispose();
  }

  void _pesan(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _simpan() async {
    final c = context.read<TransaksiController>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await c.ubah(
        t.id,
        jenis: t.type,
        nominal: parseRupiah(_nominal.text),
        kantongId: _kantong,
        kantongTujuanId: _tujuan,
        kategoriId: _kategori,
        tanggal: _tanggal,
        catatan: _catatan.text,
      );
    } on ArgumentError catch (e) {
      _pesan(e.message.toString().split(': ').last);
      return;
    }
    nav.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Perubahan disimpan')));
  }

  Future<void> _hapus() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus transaksi ini?'),
        content: const Text('Saldo kantong ikut dikoreksi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            key: const Key('transaksi.hapus.ya'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ya != true || !mounted) return;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await context.read<TransaksiController>().hapus(t.id);
    nav.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Transaksi dihapus')));
  }

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context).textTheme;
    final g = context.gemi;
    final c = context.watch<TransaksiController>();
    final masuk = t.type == JenisTransaksi.income;
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('‹ Kembali'),
        ),
        leadingWidth: 110,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Center(
              child: Text(
                t.type.label,
                style: th.bodySmall?.copyWith(color: g.ink2),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Text('Ubah transaksi', style: th.titleLarge),
            ),
            TextField(
              key: const Key('transaksi.nominal'),
              controller: _nominal,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                RibuanFormatter(),
              ],
              style: th.displaySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                prefixStyle: th.titleMedium?.copyWith(color: g.ink2),
              ),
            ),
            if (!_transfer) ...[
              const SizedBox(height: 12),
              Text('Kategori', style: th.bodySmall?.copyWith(color: g.ink2)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in c.kategori(t.type))
                    ChoiceChip(
                      key: Key('transaksi.kategori.${k.id}'),
                      label: Text(k.name),
                      selected: _kategori == k.id,
                      onSelected: (_) => setState(() => _kategori = k.id),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            BarisPilih(
              key: const Key('transaksi.kantong'),
              label: masuk ? 'Ke kantong' : 'Dari kantong',
              nilai: namaKantong(context, _kantong),
              onTap: () async {
                final id = await pilihKantong(
                  context,
                  judul: masuk ? 'Ke kantong' : 'Dari kantong',
                );
                if (id != null) setState(() => _kantong = id);
              },
            ),
            if (_transfer)
              BarisPilih(
                key: const Key('transaksi.kantongTujuan'),
                label: 'Ke kantong',
                nilai: namaKantong(context, _tujuan),
                onTap: () async {
                  final id = await pilihKantong(context, judul: 'Ke kantong');
                  if (id != null) setState(() => _tujuan = id);
                },
              ),
            BarisPilih(
              key: const Key('transaksi.tanggal'),
              label: 'Tanggal',
              nilai: fmtTanggal(_tanggal),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.parse(_tanggal),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _tanggal = ymd(d));
              },
            ),
            TextField(
              key: const Key('transaksi.catatan'),
              controller: _catatan,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('transaksi.simpanUbah'),
              onPressed: _simpan,
              child: const Text('Simpan perubahan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('transaksi.hapus'),
              onPressed: _hapus,
              style: OutlinedButton.styleFrom(
                foregroundColor: g.over,
                minimumSize: const Size.fromHeight(44),
                side: BorderSide(color: g.rule),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Hapus transaksi'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
