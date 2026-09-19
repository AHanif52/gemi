import 'package:drift/drift.dart';

import '../app/database.dart';
import 'kategori_model.dart';

class KategoriRepository {
  KategoriRepository(this._db);
  final GemiDatabase _db;

  /// Kategori aktif (tidak disembunyikan) untuk satu jenis, urut sort_order.
  Future<List<Kategori>> aktif(JenisKategori jenis) =>
      (_db.select(_db.categories)
            ..where((k) => k.type.equalsValue(jenis) & k.isHidden.equals(false))
            ..orderBy(_urut))
          .get();

  /// Semua kategori satu jenis termasuk yang disembunyikan (layar Pengaturan).
  Future<List<Kategori>> semua(JenisKategori jenis) =>
      (_db.select(_db.categories)
            ..where((k) => k.type.equalsValue(jenis))
            ..orderBy(_urut))
          .get();

  Future<int> tambah({
    required String nama,
    required JenisKategori jenis,
    required int warna,
  }) async {
    final terakhir = await (_db.selectOnly(
      _db.categories,
    )..addColumns([_db.categories.sortOrder.max()])).getSingle();
    return _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            name: nama,
            type: jenis,
            color: warna,
            sortOrder: Value(
              (terakhir.read(_db.categories.sortOrder.max()) ?? 0) + 1,
            ),
          ),
        );
  }

  Future<void> ubah(int id, {required String nama, required int warna}) =>
      (_db.update(_db.categories)..where((k) => k.id.equals(id))).write(
        CategoriesCompanion(name: Value(nama), color: Value(warna)),
      );

  Future<void> setSembunyi(int id, bool sembunyi) =>
      (_db.update(_db.categories)..where((k) => k.id.equals(id))).write(
        CategoriesCompanion(isHidden: Value(sembunyi)),
      );

  Future<void> hapus(int id) =>
      (_db.delete(_db.categories)..where((k) => k.id.equals(id))).go();

  /// Jumlah transaksi yang memakai kategori ini; kustom hanya boleh dihapus kalau 0.
  Future<int> dipakai(int id) async {
    final n = _db.transactions.id.count();
    final r =
        await (_db.selectOnly(_db.transactions)
              ..addColumns([n])
              ..where(_db.transactions.categoryId.equals(id)))
            .getSingle();
    return r.read(n) ?? 0;
  }

  static final _urut = [
    (Categories k) => OrderingTerm(expression: k.sortOrder),
    (Categories k) => OrderingTerm(expression: k.id),
  ];
}
