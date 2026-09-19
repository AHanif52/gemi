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

  /// Mutasi per kantong = pemasukan − pengeluaran − transfer keluar + transfer masuk (FR-18).
  /// Saldo = initial_balance + mutasi; kantong tanpa transaksi tidak muncul di map.
  Future<Map<int, int>> mutasi() async {
    final rows = await _db.customSelect('''
      SELECT a.id AS id,
        COALESCE((SELECT SUM(CASE type WHEN 'income' THEN amount ELSE -amount END)
                  FROM transactions WHERE account_id = a.id), 0)
      + COALESCE((SELECT SUM(amount) FROM transactions WHERE to_account_id = a.id), 0) AS mutasi
      FROM accounts a
    ''', readsFrom: {_db.accounts, _db.transactions}).get();
    return {for (final r in rows) r.read<int>('id'): r.read<int>('mutasi')};
  }
}
