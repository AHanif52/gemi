import 'package:drift/drift.dart';

import '../app/database.dart';
import 'transaksi_model.dart';

class TransaksiRepository {
  TransaksiRepository(this._db);
  final GemiDatabase _db;

  /// Semua transaksi + nama kategori/kantong, terbaru di atas (FR-03).
  Future<List<TransaksiBaris>> semua() async {
    final t = _db.transactions, k = _db.categories, a = _db.accounts;
    final tujuan = _db.alias(_db.accounts, 'tujuan');
    final q = _db.select(t).join([
      leftOuterJoin(k, k.id.equalsExp(t.categoryId)),
      innerJoin(a, a.id.equalsExp(t.accountId)),
      leftOuterJoin(tujuan, tujuan.id.equalsExp(t.toAccountId)),
    ])
      ..orderBy([OrderingTerm.desc(t.date), OrderingTerm.desc(t.createdAt), OrderingTerm.desc(t.id)]);
    final rows = await q.get();
    return [
      for (final r in rows)
        TransaksiBaris(r.readTable(t), kategori: r.readTableOrNull(k), kantong: r.readTable(a), kantongTujuan: r.readTableOrNull(tujuan)),
    ];
  }

  Future<int> tambah(TransactionsCompanion data) => _db.into(_db.transactions).insert(data);

  Future<void> hapus(int id) => (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();

  /// Transaksi terakhir yang dibuat, untuk default kategori & kantong di form (FR-05).
  Future<Transaksi?> terakhir() =>
      (_db.select(_db.transactions)..orderBy([(t) => OrderingTerm.desc(t.id)])..limit(1)).getSingleOrNull();
}
