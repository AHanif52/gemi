import 'package:flutter/foundation.dart';

import 'pengaturan_repository.dart';

/// FR-21: sembunyikan semua nominal jadi "••••••". Diingat sampai diubah lagi.
class SembunyiController extends ChangeNotifier {
  SembunyiController(this._setelan);
  final PengaturanRepository _setelan;
  static const _kunci = 'sembunyi_nominal';

  bool _aktif = false;
  bool get aktif => _aktif;

  Future<void> muat() async {
    _aktif = await _setelan.baca(_kunci) == '1';
    notifyListeners();
  }

  Future<void> toggle() async {
    _aktif = !_aktif;
    notifyListeners();
    await _setelan.tulis(_kunci, _aktif ? '1' : '0');
  }
}
