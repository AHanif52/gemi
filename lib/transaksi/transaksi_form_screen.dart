import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/format.dart';
import '../app/theme.dart';
import '../budget/budget_controller.dart';
import '../widgets/keypad_gemi.dart';
import '../widgets/pilih_kantong.dart';
import 'transaksi_controller.dart';
import 'transaksi_model.dart';

/// /transaksi/baru — langkah 1: jenis + nominal lewat keypad (FR-01).
/// Transfer selesai di sini (pilih dari/ke, Simpan); lainnya lanjut ke [TransaksiKategoriScreen].
class TransaksiFormScreen extends StatefulWidget {
  const TransaksiFormScreen({super.key});

  @override
  State<TransaksiFormScreen> createState() => _TransaksiFormScreenState();
}

class _TransaksiFormScreenState extends State<TransaksiFormScreen> {
  var _jenis = JenisTransaksi.expense;
  var _digit = '';
  int? _dari, _ke;

  int get _nominal => int.tryParse(_digit) ?? 0;

  @override
  void initState() {
    super.initState();
    final c = context.read<TransaksiController>();
    _dari = c.kantongDefault();
  }

  void _ketik(String k) => setState(() {
    if (k == '⌫') {
      _digit = _digit.isEmpty ? '' : _digit.substring(0, _digit.length - 1);
    } else if (_digit.length + k.length <= 12) {
      _digit = (_digit + k).replaceFirst(RegExp(r'^0+(?=\d)'), '');
    }
  });

  Future<void> _lanjut() async {
    if (_nominal <= 0) return _pesan('Nominal harus lebih dari 0');
    if (_jenis != JenisTransaksi.transfer) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/transaksi/baru/kategori'),
          builder: (_) => TransaksiKategoriScreen(
            jenis: _jenis,
            nominal: _nominal,
            kantongId: _dari,
          ),
        ),
      );
      return;
    }
    if (_dari == null || _ke == null) {
      return _pesan('Pilih kantong asal dan tujuan');
    }
    if (_dari == _ke) return _pesan('Kantong asal dan tujuan sama');
    await simpanTransaksi(
      context,
      jenis: _jenis,
      nominal: _nominal,
      kantongId: _dari!,
      kantongTujuanId: _ke,
      tanggal: hariIni(),
    );
  }

  void _pesan(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final g = context.gemi;
    final transfer = _jenis == JenisTransaksi.transfer;
    final judul = switch (_jenis) {
      JenisTransaksi.expense => 'Pengeluaran baru',
      JenisTransaksi.income => 'Pemasukan baru',
      JenisTransaksi.transfer => 'Transfer antar kantong',
    };
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        leadingWidth: 80,
        actions: [
          if (!transfer)
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Center(
                child: Text(
                  '1 dari 2',
                  style: t.bodySmall?.copyWith(color: g.ink2),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Text(judul, style: t.titleLarge),
              ),
              _Segmen(
                nilai: _jenis,
                onPilih: (j) => setState(() => _jenis = j),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Rp ',
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: g.ink2,
                      ),
                    ),
                    Text(
                      key: const Key('transaksi.nominal'),
                      fmtRupiah(_nominal),
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (transfer) ...[
                BarisPilih(
                  key: const Key('transaksi.kantong'),
                  label: 'Dari kantong',
                  nilai: namaKantong(context, _dari),
                  onTap: () async {
                    final id = await pilihKantong(
                      context,
                      judul: 'Dari kantong',
                    );
                    if (id != null) setState(() => _dari = id);
                  },
                ),
                BarisPilih(
                  key: const Key('transaksi.kantongTujuan'),
                  label: 'Ke kantong',
                  nilai: namaKantong(context, _ke),
                  onTap: () async {
                    final id = await pilihKantong(context, judul: 'Ke kantong');
                    if (id != null) setState(() => _ke = id);
                  },
                ),
              ] else
                Text(
                  _jenis == JenisTransaksi.income
                      ? 'Masuk ke ${namaKantong(context, _dari)}'
                      : 'Dari ${namaKantong(context, _dari)}',
                  style: t.bodySmall?.copyWith(color: g.ink2),
                ),
              const Spacer(),
              KeypadGemi(onKetik: _ketik, keyPrefix: 'transaksi.keypad'),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: FilledButton(
                  key: Key(transfer ? 'transaksi.simpan' : 'transaksi.lanjut'),
                  onPressed: _lanjut,
                  child: Text(transfer ? 'Simpan' : 'Lanjut'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// /transaksi/baru/kategori — langkah 2: kategori, kantong, tanggal, catatan, Simpan.
class TransaksiKategoriScreen extends StatefulWidget {
  const TransaksiKategoriScreen({
    super.key,
    required this.jenis,
    required this.nominal,
    this.kantongId,
  });
  final JenisTransaksi jenis;
  final int nominal;
  final int? kantongId;

  @override
  State<TransaksiKategoriScreen> createState() =>
      _TransaksiKategoriScreenState();
}

class _TransaksiKategoriScreenState extends State<TransaksiKategoriScreen> {
  final _catatan = TextEditingController();
  int? _kategori, _kantong;
  var _tanggal = hariIni();

  @override
  void initState() {
    super.initState();
    _kategori = context.read<TransaksiController>().kategoriDefault(
      widget.jenis,
    );
    _kantong = widget.kantongId;
  }

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_kategori == null) return _pesan('Pilih kategori dulu');
    if (_kantong == null) return _pesan('Pilih kantong dulu');
    await simpanTransaksi(
      context,
      jenis: widget.jenis,
      nominal: widget.nominal,
      kantongId: _kantong!,
      kategoriId: _kategori,
      tanggal: _tanggal,
      catatan: _catatan.text,
    );
  }

  void _pesan(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final g = context.gemi;
    final c = context.watch<TransaksiController>();
    final masuk = widget.jenis == JenisTransaksi.income;
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('‹ Nominal'),
        ),
        leadingWidth: 110,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Center(
              child: Text(
                '2 dari 2',
                style: t.bodySmall?.copyWith(color: g.ink2),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                widget.jenis.label,
                style: t.bodySmall?.copyWith(color: g.ink2),
              ),
              Text(
                'Rp ${fmtRupiah(widget.nominal)}',
                style: t.titleLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 24),
              Text('Kategori', style: t.bodySmall?.copyWith(color: g.ink2)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in c.kategori(widget.jenis))
                    ChoiceChip(
                      key: Key('transaksi.kategori.${k.id}'),
                      label: Text(k.name),
                      selected: _kategori == k.id,
                      onSelected: (_) => setState(() => _kategori = k.id),
                    ),
                ],
              ),
              if (!masuk && _kategori != null)
                _SisaBudget(
                  kategoriId: _kategori!,
                  nominal: widget.nominal,
                  tanggal: _tanggal,
                ),
              const SizedBox(height: 12),
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
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  hintText: 'Nasi padang',
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: FilledButton(
                  key: const Key('transaksi.simpan'),
                  onPressed: _simpan,
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sisa budget kategori setelah transaksi ini (FR-07). Kosong kalau kategori tanpa budget.
class _SisaBudget extends StatelessWidget {
  const _SisaBudget({
    required this.kategoriId,
    required this.nominal,
    required this.tanggal,
  });
  final int kategoriId, nominal;
  final String tanggal;

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final sisa = context.watch<BudgetController>().sisaSetelah(
      kategoriId: kategoriId,
      nominal: nominal,
      bulan: tanggal.substring(0, 7),
    );
    if (sisa == null) return const SizedBox.shrink();
    final nama =
        context
            .read<TransaksiController>()
            .kategori(JenisTransaksi.expense)
            .where((k) => k.id == kategoriId)
            .firstOrNull
            ?.name ??
        '';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        key: const Key('transaksi.sisaBudget'),
        sisa < 0
            ? 'Lewat budget $nama ${fmtRupiah(-sisa)} setelah ini'
            : 'Sisa budget $nama ${fmtRupiah(sisa)} setelah ini',
        style: TextStyle(fontSize: 12, color: sisa < 0 ? g.over : g.income),
      ),
    );
  }
}

/// Simpan lewat controller, kembali ke tab, toast dengan "Batalkan" 4 detik (BRD: Bisa dibatalkan).
Future<void> simpanTransaksi(
  BuildContext context, {
  required JenisTransaksi jenis,
  required int nominal,
  required int kantongId,
  int? kantongTujuanId,
  int? kategoriId,
  required String tanggal,
  String? catatan,
}) async {
  final c = context.read<TransaksiController>();
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final int id;
  try {
    id = await c.tambah(
      jenis: jenis,
      nominal: nominal,
      kantongId: kantongId,
      kantongTujuanId: kantongTujuanId,
      kategoriId: kategoriId,
      tanggal: tanggal,
      catatan: catatan,
    );
  } on ArgumentError catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(e.message.toString().split(': ').last)),
    );
    return;
  }
  nav.popUntil((r) => r.isFirst);
  messenger.showSnackBar(
    SnackBar(
      content: const Text('Transaksi tersimpan'),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(label: 'Batalkan', onPressed: () => c.hapus(id)),
    ),
  );
}

/// Pilihan jenis, gaya tab garis bawah (tokens .seg).
class _Segmen extends StatelessWidget {
  const _Segmen({required this.nilai, required this.onPilih});
  final JenisTransaksi nilai;
  final ValueChanged<JenisTransaksi> onPilih;

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final ink = Theme.of(context).colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: g.rule)),
      ),
      child: Row(
        children: [
          for (final j in JenisTransaksi.values)
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: InkWell(
                key: Key('transaksi.jenis.${j.name}'),
                onTap: () => onPilih(j),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: j == nilai ? ink : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    j.label,
                    style: TextStyle(
                      color: j == nilai ? ink : g.ink2,
                      fontWeight: j == nilai ? FontWeight.w500 : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
