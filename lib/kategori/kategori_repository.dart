import 'package:drift/drift.dart';

import '../app/database.dart';
import 'kategori_model.dart';

class KategoriRepository {
  KategoriRepository(this._db);
  final GemiDatabase _db;

  /// Kategori aktif (tidak disembunyikan) untuk satu jenis, urut sort_order.
  Future<List<Kategori>> aktif(JenisKategori jenis) => (_db.select(_db.categories)
        ..where((k) => k.type.equalsValue(jenis) & k.isHidden.equals(false))
        ..orderBy([(k) => OrderingTerm(expression: k.sortOrder), (k) => OrderingTerm(expression: k.id)]))
      .get();
}
