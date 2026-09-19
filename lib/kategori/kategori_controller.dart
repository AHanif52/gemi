import 'package:flutter/foundation.dart';

import '../app/database.dart' show Kategori;
import 'kategori_model.dart';
import 'kategori_repository.dart';

/// State layar Pengaturan › Kategori. Perubahan di sini juga memengaruhi form
/// transaksi dan budget; main.dart menyambungkan listener-nya.
class KategoriController extends ChangeNotifier {
  KategoriController(this._repo);
  final KategoriRepository _repo;

  List<Kategori> _keluar = [], _masuk = [];
  bool _siap = false;

  bool get siap => _siap;
  List<Kategori> semua(JenisKategori j) =>
      j == JenisKategori.expense ? _keluar : _masuk;
  int aktif(JenisKategori j) => semua(j).where((k) => !k.isHidden).length;

  Future<void> muat() async {
    _keluar = await _repo.semua(JenisKategori.expense);
    _masuk = await _repo.semua(JenisKategori.income);
    _siap = true;
    notifyListeners();
  }

  Future<void> tambah({
    required String nama,
    required JenisKategori jenis,
    required int warna,
  }) async {
    await _repo.tambah(nama: _nama(nama, 'tambah'), jenis: jenis, warna: warna);
    await muat();
  }

  Future<void> ubah(int id, {required String nama, required int warna}) async {
    await _repo.ubah(id, nama: _nama(nama, 'ubah'), warna: warna);
    await muat();
  }

  Future<void> sembunyikan(int id, bool sembunyi) async {
    await _repo.setSembunyi(id, sembunyi);
    await muat();
  }

  /// Kustom saja, dan hanya kalau belum pernah dipakai transaksi (FR-05).
  /// Lempar [StateError] supaya screen bisa tawarkan "sembunyikan saja".
  Future<void> hapus(Kategori k) async {
    if (k.isDefault) {
      throw ArgumentError('kategori.hapus: bawaan tidak bisa dihapus');
    }
    if (await _repo.dipakai(k.id) > 0) {
      throw StateError('kategori.hapus: masih dipakai catatan');
    }
    await _repo.hapus(k.id);
    await muat();
  }

  String _nama(String s, String aksi) {
    final n = s.trim();
    if (n.isEmpty) throw ArgumentError('kategori.$aksi: nama wajib diisi');
    return n;
  }
}
