import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../widgets/baris_gemi.dart';
import 'kunci_controller.dart';
import 'pin_screen.dart';

/// /pengaturan/kunci — nyalakan PIN, biometrik, kunci otomatis, ubah PIN (FR-16).
class KunciScreen extends StatelessWidget {
  const KunciScreen({super.key});

  Future<String?> _mintaPin(BuildContext context) => Navigator.push<String>(
    context,
    MaterialPageRoute(
      settings: const RouteSettings(name: '/pengaturan/kunci/pin'),
      builder: (_) => const PinScreen.buat(),
    ),
  );

  Future<void> _toggle(BuildContext context, bool nyala) async {
    final c = context.read<KunciController>();
    final messenger = ScaffoldMessenger.of(context);
    if (!nyala) {
      await c.matikan();
      messenger.showSnackBar(const SnackBar(content: Text('Kunci dimatikan')));
      return;
    }
    final pin = await _mintaPin(context);
    if (pin == null) return;
    await c.aturPin(pin);
    messenger.showSnackBar(const SnackBar(content: Text('PIN disimpan')));
  }

  Future<void> _ubahPin(BuildContext context) async {
    final c = context.read<KunciController>();
    final messenger = ScaffoldMessenger.of(context);
    final pin = await _mintaPin(context);
    if (pin == null) return;
    await c.aturPin(pin);
    messenger.showSnackBar(const SnackBar(content: Text('PIN diganti')));
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final t = Theme.of(context).textTheme;
    final c = context.watch<KunciController>();
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
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text('Kunci aplikasi', style: t.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'PIN hanya membuka layar. Data di HP sudah terenkripsi terlepas dari PIN.',
              style: t.bodySmall?.copyWith(color: g.ink2),
            ),
          ),
          _Saklar(
            key: const Key('kunci.aktif'),
            label: 'Kunci dengan PIN',
            nilai: c.aktif,
            onUbah: (v) => _toggle(context, v),
          ),
          if (c.aktif) ...[
            _Saklar(
              key: const Key('kunci.biometrik'),
              label: 'Sidik jari / wajah',
              sub: c.bisaBiometrik
                  ? 'PIN tetap diminta kalau biometrik gagal'
                  : 'Tidak tersedia di perangkat ini',
              nilai: c.biometrik && c.bisaBiometrik,
              onUbah: c.bisaBiometrik ? c.aturBiometrik : null,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Text(
                'Kunci otomatis setelah',
                style: t.bodySmall?.copyWith(color: g.ink2),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final d in KunciController.pilihanOtomatis)
                  ChoiceChip(
                    key: Key('kunci.otomatis.$d'),
                    label: Text(KunciController.labelOtomatis(d)),
                    selected: c.otomatis == d,
                    onSelected: (_) => c.aturOtomatis(d),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            BarisTautan(
              key: const Key('kunci.ubahPin'),
              label: 'Ubah PIN',
              onTap: () => _ubahPin(context),
            ),
            BarisTautan(
              key: const Key('kunci.coba'),
              label: 'Coba layar kunci',
              onTap: c.kunci,
              tanpaGarisAtas: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// Baris label + switch, garis bawah tipis seperti BarisTautan.
class _Saklar extends StatelessWidget {
  const _Saklar({
    super.key,
    required this.label,
    this.sub,
    required this.nilai,
    required this.onUbah,
  });

  final String label;
  final String? sub;
  final bool nilai;
  final ValueChanged<bool>? onUbah;

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: g.rule)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                if (sub != null)
                  Text(sub!, style: TextStyle(fontSize: 13, color: g.ink2)),
              ],
            ),
          ),
          Switch(value: nilai, onChanged: onUbah),
        ],
      ),
    );
  }
}
