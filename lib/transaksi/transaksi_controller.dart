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
  List<Kategori> kategori(JenisTransaksi j) =>
      j == JenisTransaksi.income ? _kategoriMasuk : _kategoriKeluar;

  /// Default form: kategori/kantong terakhir dipakai; pertama kali kategori pertama, kantong pertama (FR-05).
  int? kategoriDefault(JenisTransaksi j) {
    final list = kategori(j);
    final last = _terakhir;
    if (last != null &&
        last.type == j &&
        list.any((k) => k.id == last.categoryId)) {
      return last.categoryId;
    }
    return list.isEmpty ? null : list.first.id;
  }

  int? kantongDefault() =>
      _terakhir?.accountId ?? _kantong.daftar.firstOrNull?.id;

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
    final id = await _repo.tambah(
      _susun(
        aksi: 'tambah',
        jenis: jenis,
        nominal: nominal,
        kantongId: kantongId,
        kantongTujuanId: kantongTujuanId,
        kategoriId: kategoriId,
        tanggal: tanggal,
        catatan: catatan,
      ),
    );
    await _segarkan();
    return id;
  }

  /// Ubah transaksi yang ada (FR-02). Jenis ikut dikirim karena validasi bergantung padanya.
  Future<void> ubah(
    int id, {
    required JenisTransaksi jenis,
    required int nominal,
    required int kantongId,
    int? kantongTujuanId,
    int? kategoriId,
    required String tanggal,
    String? catatan,
  }) async {
    await _repo.ubah(
      id,
      _susun(
        aksi: 'ubah',
        jenis: jenis,
        nominal: nominal,
        kantongId: kantongId,
        kantongTujuanId: kantongTujuanId,
        kategoriId: kategoriId,
        tanggal: tanggal,
        catatan: catatan,
      ),
    );
    await _segarkan();
  }

  /// Validasi + bentuk companion. Satu tempat untuk tambah dan ubah.
  TransactionsCompanion _susun({
    required String aksi,
    required JenisTransaksi jenis,
    required int nominal,
    required int kantongId,
    int? kantongTujuanId,
    int? kategoriId,
    required String tanggal,
    String? catatan,
  }) {
    if (nominal <= 0) {
      throw ArgumentError('transaksi.$aksi: nominal harus lebih dari 0');
    }
    final transfer = jenis == JenisTransaksi.transfer;
    if (transfer && kantongTujuanId == null) {
      throw ArgumentError('transaksi.$aksi: transfer butuh kantong tujuan');
    }
    if (transfer && kantongTujuanId == kantongId) {
      throw ArgumentError('transaksi.$aksi: kantong asal dan tujuan sama');
    }
    if (!transfer && kategoriId == null) {
      throw ArgumentError('transaksi.$aksi: kategori wajib dipilih');
    }
    final note = catatan?.trim();
    return TransactionsCompanion(
      type: Value(jenis),
      amount: Value(nominal),
      accountId: Value(kantongId),
      toAccountId: Value(transfer ? kantongTujuanId : null),
      categoryId: Value(transfer ? null : kategoriId),
      date: Value(tanggal),
      note: Value(note == null || note.isEmpty ? null : note),
    );
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
