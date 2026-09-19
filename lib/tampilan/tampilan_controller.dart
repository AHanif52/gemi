import 'package:flutter/material.dart';

import '../pengaturan/pengaturan_repository.dart';

/// NFR-10: mode terang/gelap ikut sistem, bisa dipaksa dari Pengaturan › Tampilan.
class TampilanController extends ChangeNotifier {
  TampilanController(this._setelan);
  final PengaturanRepository _setelan;
  static const _kunci = 'tampilan_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  String get keterangan => switch (_mode) {
    ThemeMode.system => 'Ikuti sistem',
    ThemeMode.light => 'Terang',
    ThemeMode.dark => 'Gelap',
  };

  Future<void> muat() async {
    _mode =
        ThemeMode.values.asNameMap()[await _setelan.baca(_kunci) ?? ''] ??
        ThemeMode.system;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    await _setelan.tulis(_kunci, m.name);
  }
}
