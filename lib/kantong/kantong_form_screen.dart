import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/format.dart';
import '../app/theme.dart';
import '../widgets/ribuan_formatter.dart';
import 'kantong_controller.dart';
import 'kantong_model.dart';

/// /kantong/baru dan /mulai (first run, [pertama] = true). Satu form, dua salinan teks.
class KantongFormScreen extends StatefulWidget {
  const KantongFormScreen({super.key, this.pertama = false});
  final bool pertama;

  @override
  State<KantongFormScreen> createState() => _KantongFormScreenState();
}

class _KantongFormScreenState extends State<KantongFormScreen> {
  final _nama = TextEditingController();
  final _saldo = TextEditingController();
  var _jenis = JenisKantong.bank;

  @override
  void dispose() {
    _nama.dispose();
    _saldo.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final c = context.read<KantongController>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await c.tambah(
        nama: _nama.text,
        jenis: _jenis,
        saldoAwal: parseRupiah(_saldo.text),
      );
    } on ArgumentError {
      messenger.showSnackBar(
        const SnackBar(content: Text('Isi nama kantong dulu')),
      );
      return;
    }
    if (widget.pertama) {
      nav.pushReplacementNamed('/beranda');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Kantong ${_nama.text.trim()} dibuat. Ketuk + untuk transaksi pertama.',
          ),
        ),
      );
    } else {
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Kantong ditambahkan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final g = context.gemi;
    final pertama = widget.pertama;
    return Scaffold(
      appBar: pertama
          ? null
          : AppBar(
              leading: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              leadingWidth: 80,
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pertama) const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Text(
                  pertama ? 'Gemi' : 'Kantong baru',
                  style: pertama ? t.displaySmall : t.titleLarge,
                ),
              ),
              if (pertama)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    'Gemi nastiti: hemat dan teliti. Catat uang masuk dan keluar, tanpa internet, tanpa akun. '
                    'Mulai dari satu kantong: rekening, e-money, atau dompet.',
                    style: t.bodyMedium?.copyWith(color: g.ink2),
                  ),
                ),
              TextField(
                key: const Key('kantong.nama'),
                controller: _nama,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: pertama ? 'Nama kantong' : 'Nama',
                  hintText: 'BCA',
                ),
              ),
              const SizedBox(height: 12),
              Text('Jenis', style: t.bodySmall?.copyWith(color: g.ink2)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  for (final j in JenisKantong.values)
                    ChoiceChip(
                      key: Key('kantong.jenis.${j.name}'),
                      label: Text(j.label),
                      selected: _jenis == j,
                      onSelected: (_) => setState(() => _jenis = j),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('kantong.saldo'),
                controller: _saldo,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  RibuanFormatter(),
                ],
                style: t.displaySmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  labelText: 'Saldo sekarang',
                  hintText: '0',
                  prefixText: 'Rp ',
                  prefixStyle: t.titleMedium?.copyWith(color: g.ink2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pertama
                    ? 'Lihat di aplikasi bank atau e-money, ketik apa adanya. Kantong lain bisa ditambah nanti.'
                    : 'Isi sesuai saldo di aplikasi bank atau e-money. Catatan berikutnya menambah atau mengurangi dari angka ini.',
                style: t.bodySmall?.copyWith(fontSize: 12, color: g.ink2),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: FilledButton(
                  key: Key(pertama ? 'mulai.simpan' : 'kantong.simpan'),
                  onPressed: _simpan,
                  child: Text(pertama ? 'Mulai mencatat' : 'Simpan kantong'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
