import 'package:flutter/foundation.dart';

import '../app/format.dart';
import 'budget_model.dart';
import 'budget_repository.dart';

/// Cache ringkasan budget per bulan. Bulan yang ditampilkan adalah urusan layar;
/// controller hanya menjawab [data] untuk bulan mana pun dan memuat yang belum ada.
class BudgetController extends ChangeNotifier {
  BudgetController(this._repo);
  final BudgetRepository _repo;

  final _cache = <String, DataBulan>{};
  final _sedangMuat = <String>{};

  /// Null selagi bulan itu dimuat; layar tampilkan kosong dulu lalu dibangun ulang.
  DataBulan? data(String bulan) {
    final d = _cache[bulan];
    if (d == null && _sedangMuat.add(bulan)) _muatBulan(bulan).then((_) => _sedangMuat.remove(bulan));
    return d;
  }

  /// Sisa budget kategori setelah [nominal] ditambahkan; null kalau kategori tanpa budget
  /// atau bulan belum dimuat (FR-07).
  int? sisaSetelah({required int kategoriId, required int nominal, required String bulan}) {
    final b = data(bulan)?.baris.where((x) => x.kategori.id == kategoriId).firstOrNull;
    if (b == null || b.plafon == 0) return null;
    return b.sisa - nominal;
  }

  Future<void> simpan(String bulan, Map<int, int> plafon) async {
    await _repo.simpan(bulan, plafon);
    await muat();
  }

  /// Muat ulang semua bulan yang pernah diminta (dipanggil saat transaksi berubah).
  Future<void> muat() async {
    for (final b in _cache.keys.toList()) {
      await _muatBulan(b);
    }
  }

  Future<void> _muatBulan(String bulan) async {
    var plafon = await _repo.plafon(bulan);
    // FR-06: bulan baru tanpa budget menyalin bulan sebelumnya. Hanya untuk bulan ini
    // dan mendatang; bulan lampau dibiarkan kosong supaya riwayat tidak dikarang.
    if (plafon.isEmpty && bulan.compareTo(bulanIni()) >= 0) {
      final lalu = await _repo.plafon(geserBulan(bulan, -1));
      if (lalu.isNotEmpty) {
        await _repo.simpan(bulan, lalu);
        plafon = lalu;
      }
    }
    final pakai = await _repo.pakai(bulan);
    final kategori = await _repo.kategoriKeluar();
    _cache[bulan] = DataBulan(bulan, [
      for (final k in kategori)
        if ((plafon[k.id] ?? 0) > 0 || (pakai[k.id] ?? 0) > 0) BarisBudget(kategori: k, plafon: plafon[k.id] ?? 0, pakai: pakai[k.id] ?? 0),
    ]);
    notifyListeners();
  }
}
