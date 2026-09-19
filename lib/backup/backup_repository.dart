import 'package:drift/drift.dart';

import '../app/database.dart';

/// Dump & restore seluruh isi DB apa adanya (BRD: file backup = keempat tabel).
class BackupRepository {
  BackupRepository(this._db);
  final GemiDatabase _db;

  static const versiData = 1;

  Future<Map<String, Object?>> dump() async => {
    'version': versiData,
    'exported_at': DateTime.now().toIso8601String(),
    'accounts': [
      for (final r in await _db.select(_db.accounts).get()) r.toJson(),
    ],
    'categories': [
      for (final r in await _db.select(_db.categories).get()) r.toJson(),
    ],
    'transactions': [
      for (final r in await _db.select(_db.transactions).get()) r.toJson(),
    ],
    'budgets': [
      for (final r in await _db.select(_db.budgets).get()) r.toJson(),
    ],
  };

  /// Timpa penuh: semua tabel dikosongkan lalu diisi dari [isi], dalam satu transaksi (NFR-03).
  Future<void> restore(Map<String, Object?> isi) {
    if (isi['version'] != versiData) {
      throw FormatException(
        'backup: versi data ${isi['version']} tidak dikenal',
      );
    }
    List<Map<String, Object?>> baris(String k) => [
      for (final r in isi[k] as List) (r as Map).cast<String, Object?>(),
    ];
    return _db.transaction(() async {
      await _db.delete(_db.budgets).go();
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.accounts).go();
      await _db.batch((b) {
        b.insertAll(_db.accounts, [
          for (final r in baris('accounts')) Kantong.fromJson(r),
        ]);
        b.insertAll(_db.categories, [
          for (final r in baris('categories')) Kategori.fromJson(r),
        ]);
        b.insertAll(_db.transactions, [
          for (final r in baris('transactions')) Transaksi.fromJson(r),
        ]);
        b.insertAll(_db.budgets, [
          for (final r in baris('budgets')) Budget.fromJson(r),
        ]);
      });
    });
  }

  /// Jumlah transaksi & kantong untuk keterangan "backup terakhir".
  Future<(int, int)> hitung() async {
    final t = await (_db.selectOnly(
      _db.transactions,
    )..addColumns([_db.transactions.id.count()])).getSingle();
    final a = await (_db.selectOnly(
      _db.accounts,
    )..addColumns([_db.accounts.id.count()])).getSingle();
    return (
      t.read(_db.transactions.id.count()) ?? 0,
      a.read(_db.accounts.id.count()) ?? 0,
    );
  }
}
