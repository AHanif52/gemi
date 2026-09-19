import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../widgets/keypad_gemi.dart';
import 'kunci_controller.dart';

/// Layar PIN (FR-16). Dua pemakaian:
/// - [PinScreen.buat]: minta PIN dua kali, pop dengan String PIN (null = batal).
/// - [PinScreen.buka]: gerbang saat terkunci; tanpa tombol batal, biometrik
///   dicoba otomatis kalau aktif. Tidak pernah di-pop, hilang sendiri saat
///   controller tidak terkunci lagi.
class PinScreen extends StatefulWidget {
  const PinScreen.buat({super.key}) : gerbang = false;
  const PinScreen.buka({super.key}) : gerbang = true;

  final bool gerbang;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _buf = '';
  String _pertama = ''; // mode buat: isi setelah 4 angka pertama
  String _hint = '';
  Timer? _detik;

  @override
  void initState() {
    super.initState();
    if (widget.gerbang) {
      final c = context.read<KunciController>();
      if (c.biometrik && c.bisaBiometrik) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _bio());
      }
      // Hitung mundur jeda tampil per detik.
      _detik = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && c.sisaJeda != null) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _detik?.cancel();
    super.dispose();
  }

  Future<void> _bio() async {
    await context.read<KunciController>().bukaBiometrik();
  }

  Future<void> _ketik(String k) async {
    if (k == '⌫') {
      setState(
        () => _buf = _buf.isEmpty ? '' : _buf.substring(0, _buf.length - 1),
      );
      return;
    }
    if (_buf.length >= 4) return;
    setState(() {
      _buf += k;
      _hint = '';
    });
    if (_buf.length < 4) return;
    final pin = _buf;
    if (!widget.gerbang) {
      if (_pertama.isEmpty) {
        setState(() {
          _pertama = pin;
          _buf = '';
        });
      } else if (pin == _pertama) {
        Navigator.pop(context, pin);
      } else {
        setState(() {
          _pertama = '';
          _buf = '';
          _hint = 'PIN tidak sama, ulangi dari awal';
        });
      }
      return;
    }
    final c = context.read<KunciController>();
    final ok = await c.buka(pin);
    if (!mounted || ok) return;
    setState(() {
      _buf = '';
      _hint = c.sisaJeda == null ? 'PIN salah' : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final ink = Theme.of(context).colorScheme.onSurface;
    final t = Theme.of(context).textTheme;
    final c = context.watch<KunciController>();
    final jeda = widget.gerbang ? c.sisaJeda : null;
    final judul = widget.gerbang
        ? 'Masukkan PIN'
        : _pertama.isEmpty
        ? 'Buat PIN'
        : 'Ulangi PIN';
    final hint = jeda != null
        ? 'Terlalu banyak salah. Coba lagi ${jeda.inSeconds + 1} detik lagi.'
        : _hint.isNotEmpty
        ? _hint
        : widget.gerbang
        ? ''
        : '4 angka';
    return PopScope(
      canPop: !widget.gerbang,
      child: Scaffold(
        appBar: widget.gerbang
            ? null
            : AppBar(
                leading: TextButton(
                  key: const Key('kunci.batal'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                leadingWidth: 90,
              ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),
                Text(judul, style: t.titleLarge),
                const SizedBox(height: 24),
                Row(
                  key: const Key('kunci.pin'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _buf.length ? ink : Colors.transparent,
                          border: Border.all(color: ink, width: 1.5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(
                    color: jeda != null || _hint.isNotEmpty ? g.over : g.ink2,
                  ),
                ),
                if (widget.gerbang && c.biometrik && c.bisaBiometrik)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: OutlinedButton(
                      key: const Key('kunci.biometrik'),
                      onPressed: _bio,
                      child: const Text('Pakai sidik jari / wajah'),
                    ),
                  ),
                const Spacer(),
                IgnorePointer(
                  ignoring: jeda != null,
                  child: Opacity(
                    opacity: jeda != null ? .4 : 1,
                    child: KeypadGemi(
                      onKetik: _ketik,
                      keyPrefix: 'kunci.keypad',
                      tombol: KeypadGemi.pin,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
