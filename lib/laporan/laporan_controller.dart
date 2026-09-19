import 'package:flutter/foundation.dart';

import 'laporan_model.dart';
import 'laporan_repository.dart';

/// Cache [Ringkasan] per rentang tanggal; pola sama dengan BudgetController.
/// Layar minta rentang apa pun lewat [data]; null selagi dimuat.
class LaporanController extends ChangeNotifier {
  LaporanController(this._repo);
  final LaporanRepository _repo;

  final _cache = <String, Ringkasan>{};
  final _sedangMuat = <String>{};

  Ringkasan? data(String dari, String sampai) {
    final key = '$dari|$sampai';
    final d = _cache[key];
    if (d == null && _sedangMuat.add(key)) _muat(dari, sampai).then((_) => _sedangMuat.remove(key));
    return d;
  }

  /// Muat ulang semua rentang yang pernah diminta (saat transaksi berubah).
  Future<void> muat() async {
    for (final r in _cache.values.toList()) {
      await _muat(r.dari, r.sampai);
    }
  }

  Future<void> _muat(String dari, String sampai) async {
    _cache['$dari|$sampai'] = await _repo.ringkasan(dari, sampai);
    notifyListeners();
  }
}
