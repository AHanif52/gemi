import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../kantong/kantong_controller.dart';
import '../kategori/kategori_controller.dart';
import 'backup_controller.dart';
import 'backup_service.dart';

/// /pengaturan/backup — buat backup terenkripsi, pulihkan dari file (FR-14).
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  Future<void> _buat(BuildContext context) async {
    final pass = await _mintaPassphrase(context, ulangi: true);
    if (pass == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final c = context.read<BackupController>();
    _sibuk(context, 'Mengenkripsi backup…');
    try {
      final ok = await c.buat(pass);
      messenger.showSnackBar(
        SnackBar(
          content: Text(ok ? 'File backup dibagikan' : 'Backup dibatalkan'),
        ),
      );
    } finally {
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _pulihkan(BuildContext context) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Backup Gemi', extensions: ['json']),
      ],
    );
    if (file == null || !context.mounted) return;
    final pass = await _mintaPassphrase(context, ulangi: false);
    if (pass == null || !context.mounted) return;
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti semua data di HP ini?'),
        content: const Text(
          'Semua kantong, transaksi, kategori, dan budget diganti dengan isi backup. Tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            key: const Key('backup.pulihkan.ya'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ganti'),
          ),
        ],
      ),
    );
    if (ya != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final backup = context.read<BackupController>();
    final kantong = context.read<KantongController>();
    final kategori = context.read<KategoriController>();
    _sibuk(context, 'Memulihkan data…');
    String pesan;
    try {
      await backup.pulihkan(file, pass);
      // Kategori memicu transaksi -> budget & laporan lewat listener di main.dart.
      await kantong.muat();
      await kategori.muat();
      pesan = 'Data dipulihkan';
    } on PassphraseSalah {
      pesan = 'Passphrase salah untuk file ini';
    } on FormatException catch (e) {
      pesan = e.message.split(': ').last;
    }
    if (context.mounted) Navigator.pop(context);
    messenger.showSnackBar(SnackBar(content: Text(pesan)));
  }

  void _sibuk(BuildContext context, String s) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 16),
          Text(s),
        ],
      ),
    ),
  );

  Future<String?> _mintaPassphrase(
    BuildContext context, {
    required bool ulangi,
  }) => showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _FormPassphrase(ulangi: ulangi),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final t = Theme.of(context).textTheme;
    final c = context.watch<BackupController>();
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('‹ Pengaturan'),
        ),
        leadingWidth: 130,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text('Backup & restore', style: t.titleLarge),
          ),
          Text(
            'Backup adalah satu file terenkripsi dengan passphrase pilihanmu. Simpan di Drive, iCloud, atau kirim ke diri sendiri. '
            'Tanpa passphrase, file tidak bisa dibuka siapa pun, termasuk kamu.',
            style: t.bodySmall?.copyWith(color: g.ink2),
          ),
          const SizedBox(height: 24),
          Text('Backup terakhir', style: t.bodySmall?.copyWith(color: g.ink2)),
          const SizedBox(height: 4),
          Text(
            c.terakhir == null ? 'Belum pernah' : _fmtWaktu(c.terakhir!),
            style: t.titleLarge,
          ),
          if (c.ringkas != null)
            Text(
              '${c.keterangan.replaceFirst('Backup terakhir ', '')} · ${c.ringkas}',
              style: t.bodySmall?.copyWith(color: g.ink2),
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('backup.buat'),
            onPressed: () => _buat(context),
            child: const Text('Buat backup sekarang'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('backup.pulihkan'),
            onPressed: () => _pulihkan(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              side: BorderSide(color: g.rule),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Pulihkan dari file backup'),
          ),
        ],
      ),
    );
  }

  String _fmtWaktu(DateTime d) {
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${bulan[d.month - 1]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';
  }
}

class _FormPassphrase extends StatefulWidget {
  const _FormPassphrase({required this.ulangi});
  final bool ulangi;

  @override
  State<_FormPassphrase> createState() => _FormPassphraseState();
}

class _FormPassphraseState extends State<_FormPassphrase> {
  final _a = TextEditingController(), _b = TextEditingController();
  String? _galat;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _lanjut() {
    if (widget.ulangi && _a.text.length < 8) {
      return setState(() => _galat = 'Passphrase minimal 8 karakter');
    }
    if (widget.ulangi && _a.text != _b.text) {
      return setState(() => _galat = 'Passphrase tidak sama');
    }
    if (_a.text.isEmpty) {
      return setState(() => _galat = 'Masukkan passphrase file');
    }
    Navigator.pop(context, _a.text);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ulangi ? 'Passphrase backup' : 'Passphrase file',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('backup.passphrase'),
              controller: _a,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: widget.ulangi ? 'Passphrase' : 'Passphrase file',
                hintText: widget.ulangi ? 'Minimal 8 karakter' : null,
              ),
            ),
            if (widget.ulangi) ...[
              const SizedBox(height: 12),
              TextField(
                key: const Key('backup.passphrase2'),
                controller: _b,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Ulangi passphrase',
                ),
                onSubmitted: (_) => _lanjut(),
              ),
            ],
            if (_galat != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _galat!,
                  style: TextStyle(fontSize: 12, color: g.over),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('backup.lanjut'),
              onPressed: _lanjut,
              child: Text(widget.ulangi ? 'Buat backup' : 'Pulihkan'),
            ),
          ],
        ),
      ),
    );
  }
}
