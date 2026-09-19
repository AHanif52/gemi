import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../app/database.dart';
import '../kantong/kantong_controller.dart';
import '../kategori/kategori_model.dart';
import '../kategori/kategori_repository.dart';
import 'transaksi_model.dart';
import 'transaksi_repository.dart';

/// State daftar transaksi + aksi tambah/hapus. Setiap perubahan memuat ulang
/// [KantongController] karena saldo kantong ikut berubah.
class TransaksiController extends ChangeNotifier {
  TransaksiController(this._repo, this._kategoriRepo, this._kantong);
  final TransaksiRepository _repo;
  final KategoriRepository _kategoriRepo;
  final KantongController _kantong;

  List<TransaksiBaris> _daftar = [];
  List<Kategori> _kategoriKeluar = [], _kategoriMasuk = [];
  Transaksi? _terakhir;

  List<TransaksiBaris> get daftar => _daftar;
  List<Kategori> kategori(JenisTransaksi j) => j == JenisTransaksi.income ? _kategoriMasuk : _kategoriKeluar;

  /// Default form: kategori/kantong terakhir dipakai; pertama kali kategori pertama, kantong pertama (FR-05).
  int? kategoriDefault(JenisTransaksi j) {
    final list = kategori(j);
    final last = _terakhir;
    if (last != null && last.type == j && list.any((k) => k.id == last.categoryId)) return last.categoryId;
    return list.isEmpty ? null : list.first.id;
  }

  int? kantongDefault() => _terakhir?.accountId ?? _kantong.daftar.firstOrNull?.id;

  Future<void> muat() async {
    _daftar = await _repo.semua();
    _kategoriKeluar = await _kategoriRepo.aktif(JenisKategori.expense);
    _kategoriMasuk = await _kategoriRepo.aktif(JenisKategori.income);
    _terakhir = await _repo.terakhir();
    notifyListeners();
  }

  /// Simpan transaksi baru; kembalikan id supaya bisa dibatalkan lewat [hapus].
  Future<int> tambah({
    required JenisTransaksi jenis,
    required int nominal,
    required int kantongId,
    int? kantongTujuanId,
    int? kategoriId,
    required String tanggal,
    String? catatan,
  }) async {
    if (nominal <= 0) throw ArgumentError('transaksi.tambah: nominal harus lebih dari 0');
    final transfer = jenis == JenisTransaksi.transfer;
    if (transfer && kantongTujuanId == null) throw ArgumentError('transaksi.tambah: transfer butuh kantong tujuan');
    if (transfer && kantongTujuanId == kantongId) throw ArgumentError('transaksi.tambah: kantong asal dan tujuan sama');
    if (!transfer && kategoriId == null) throw ArgumentError('transaksi.tambah: kategori wajib dipilih');
    final id = await _repo.tambah(TransactionsCompanion.insert(
      type: jenis,
      amount: nominal,
      accountId: kantongId,
      toAccountId: Value(transfer ? kantongTujuanId : null),
      categoryId: Value(transfer ? null : kategoriId),
      date: tanggal,
      note: Value(catatan?.trim().isEmpty == true ? null : catatan?.trim()),
    ));
    await _segarkan();
    return id;
  }

  Future<void> hapus(int id) async {
    await _repo.hapus(id);
    await _segarkan();
  }

  Future<void> _segarkan() async {
    await muat();
    await _kantong.muat();
  }
}
