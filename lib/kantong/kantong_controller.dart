import 'package:flutter/foundation.dart';

import '../app/database.dart' show Kantong;
import 'kantong_model.dart';
import 'kantong_repository.dart';

/// State daftar kantong + aksi. Screen baca dari sini, tidak pernah dari repository.
class KantongController extends ChangeNotifier {
  KantongController(this._repo);
  final KantongRepository _repo;

  List<Kantong> _daftar = [];
  bool _siap = false;

  List<Kantong> get daftar => _daftar;
  bool get siap => _siap;
  bool get kosong => _siap && _daftar.isEmpty;
  int get total => _daftar.fold(0, (a, k) => a + saldo(k));
  int saldo(Kantong k) => _repo.saldo(k);

  Future<void> muat() async {
    _daftar = await _repo.semua();
    _siap = true;
    notifyListeners();
  }

  /// Nama wajib; lempar [ArgumentError] supaya screen tampilkan pesan, bukan diam.
  Future<void> tambah({required String nama, required JenisKantong jenis, required int saldoAwal}) async {
    final n = nama.trim();
    if (n.isEmpty) throw ArgumentError('kantong.tambah: nama wajib diisi');
    await _repo.tambah(nama: n, jenis: jenis, saldoAwal: saldoAwal);
    await muat();
  }
}
