import 'package:drift/drift.dart';

import '../app/database.dart';
import 'kantong_model.dart';

/// Baca/tulis tabel accounts. Tidak tahu widget, tidak tahu state.
class KantongRepository {
  KantongRepository(this._db);
  final GemiDatabase _db;

  /// Semua kantong aktif, urut sort_order lalu id.
  Future<List<Kantong>> semua() => (_db.select(_db.accounts)
        ..where((a) => a.isArchived.equals(false))
        ..orderBy([(a) => OrderingTerm(expression: a.sortOrder), (a) => OrderingTerm(expression: a.id)]))
      .get();

  Future<int> tambah({required String nama, required JenisKantong jenis, required int saldoAwal}) =>
      _db.into(_db.accounts).insert(AccountsCompanion.insert(name: nama, type: jenis, initialBalance: saldoAwal));

  /// Saldo = initial_balance + transaksi di kantong ini (FR-18).
  // ponytail: tabel transaksi belum ada, saldo = saldo awal. Ganti jadi JOIN saat fitur transaksi masuk.
  int saldo(Kantong k) => k.initialBalance;
}
