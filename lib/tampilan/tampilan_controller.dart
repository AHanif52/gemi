import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pengaturan/pengaturan_repository.dart';

/// Pengaturan › Tampilan: mode terang/gelap (NFR-10), hari awal minggu, dan
/// blokir screenshot / pratinjau app switcher (FLAG_SECURE, BRD ancaman 1.1).
class TampilanController extends ChangeNotifier {
  TampilanController(this._setelan);
  final PengaturanRepository _setelan;
  static const _kunci = 'tampilan_mode';
  static const _kunciAwalMinggu = 'minggu_awal'; // '1' Senin, '7' Minggu
  static const _kunciLayarAman = 'layar_aman'; // '1' / '0', default '1'
  static const _layar = MethodChannel('id.gemi/layar');

  ThemeMode _mode = ThemeMode.system;
  int _awalMinggu = DateTime.monday;
  bool _layarAman = true;

  ThemeMode get mode => _mode;
  int get awalMinggu => _awalMinggu;
  bool get layarAman => _layarAman;
  String get keterangan => switch (_mode) {
    ThemeMode.system => 'Ikuti sistem',
    ThemeMode.light => 'Terang',
    ThemeMode.dark => 'Gelap',
  };

  Future<void> muat() async {
    _mode =
        ThemeMode.values.asNameMap()[await _setelan.baca(_kunci) ?? ''] ??
        ThemeMode.system;
    _awalMinggu = await _setelan.baca(_kunciAwalMinggu) == '7'
        ? DateTime.sunday
        : DateTime.monday;
    _layarAman = await _setelan.baca(_kunciLayarAman) != '0';
    notifyListeners();
    await _terapkanLayarAman();
  }

  Future<void> setAwalMinggu(int hari) async {
    _awalMinggu = hari;
    notifyListeners();
    await _setelan.tulis(_kunciAwalMinggu, '$hari');
  }

  Future<void> setLayarAman(bool aktif) async {
    _layarAman = aktif;
    notifyListeners();
    await _setelan.tulis(_kunciLayarAman, aktif ? '1' : '0');
    await _terapkanLayarAman();
  }

  /// Kirim ke MainActivity (Android). Di test dan iOS channel tidak ada:
  /// diabaikan. ponytail: iOS belum blur saat background, tambah di AppDelegate.
  Future<void> _terapkanLayarAman() async {
    try {
      await _layar.invokeMethod('aman', _layarAman);
    } on MissingPluginException {
      /* tanpa platform */
    }
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    await _setelan.tulis(_kunci, m.name);
  }
}
