import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/database.dart' show Kategori;
import '../app/theme.dart';
import 'kategori_controller.dart';
import 'kategori_model.dart';

/// Kategori baru atau ubah. Jenis hanya bisa dipilih saat baru: mengubah jenis
/// kategori yang sudah dipakai akan merusak laporan dan budget lama.
class KategoriFormScreen extends StatefulWidget {
  const KategoriFormScreen({super.key, this.kategori, required this.jenisAwal});
  final Kategori? kategori;
  final JenisKategori jenisAwal;

  @override
  State<KategoriFormScreen> createState() => _KategoriFormScreenState();
}

class _KategoriFormScreenState extends State<KategoriFormScreen> {
  late final _nama = TextEditingController(text: widget.kategori?.name ?? '');
  late var _jenis = widget.kategori?.type ?? widget.jenisAwal;
  late var _warna = widget.kategori?.color ?? 0;

  Kategori? get k => widget.kategori;

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  void _pesan(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _simpan() async {
    final c = context.read<KategoriController>();
    final nav = Navigator.of(context);
    try {
      if (k == null) {
        await c.tambah(nama: _nama.text, jenis: _jenis, warna: _warna);
      } else {
        await c.ubah(k!.id, nama: _nama.text, warna: _warna);
      }
    } on ArgumentError {
      _pesan('Nama kategori wajib diisi');
      return;
    }
    nav.pop();
    _pesan('Kategori disimpan');
  }

  /// Bawaan: sembunyikan/tampilkan. Kustom: hapus kalau belum dipakai, kalau tidak sembunyikan.
  Future<void> _sekunder() async {
    final c = context.read<KategoriController>();
    final nav = Navigator.of(context);
    final kat = k!;
    if (kat.isHidden) {
      await c.sembunyikan(kat.id, false);
      nav.pop();
      _pesan('Kategori ditampilkan lagi');
      return;
    }
    if (kat.isDefault) {
      await c.sembunyikan(kat.id, true);
      nav.pop();
      _pesan('Kategori disembunyikan');
      return;
    }
    try {
      await c.hapus(kat);
      nav.pop();
      _pesan('Kategori dihapus');
    } on StateError {
      await c.sembunyikan(kat.id, true);
      nav.pop();
      _pesan('Masih dipakai catatan, jadi disembunyikan saja');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final g = context.gemi;
    final ink = Theme.of(context).colorScheme.onSurface;
    final labelSekunder = k == null
        ? null
        : k!.isHidden
        ? 'Tampilkan lagi'
        : k!.isDefault
        ? 'Sembunyikan kategori'
        : 'Hapus kategori';
    return Scaffold(
      appBar: AppBar(
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
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Text(
                  k == null ? 'Kategori baru' : 'Ubah kategori',
                  style: t.titleLarge,
                ),
              ),
              TextField(
                key: const Key('kategori.nama'),
                controller: _nama,
                autofocus: k == null,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  hintText: 'Kopi',
                ),
              ),
              if (k == null) ...[
                const SizedBox(height: 12),
                Text('Jenis', style: t.bodySmall?.copyWith(color: g.ink2)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final j in const [
                      JenisKategori.expense,
                      JenisKategori.income,
                    ])
                      ChoiceChip(
                        key: Key('kategori.jenis.${j.name}'),
                        label: Text(
                          j == JenisKategori.expense
                              ? 'Pengeluaran'
                              : 'Pemasukan',
                        ),
                        selected: _jenis == j,
                        onSelected: (_) => setState(() => _jenis = j),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text('Warna', style: t.bodySmall?.copyWith(color: g.ink2)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < 6; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        key: Key('kategori.warna.$i'),
                        onTap: () => setState(() => _warna = i),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _warna == i ? ink : g.rule,
                              width: _warna == i ? 2 : 1,
                            ),
                          ),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: g.kategori(i),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Warna hanya dipakai di grafik komposisi.',
                style: TextStyle(fontSize: 12, color: g.ink2),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('kategori.simpan'),
                onPressed: _simpan,
                child: const Text('Simpan kategori'),
              ),
              if (labelSekunder != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('kategori.sekunder'),
                  onPressed: _sekunder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: labelSekunder == 'Hapus kategori'
                        ? g.over
                        : ink,
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(color: g.rule),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(labelSekunder),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
