import 'package:drift/drift.dart';

import '../app/database.dart';
import '../kategori/kategori_model.dart';
import '../transaksi/transaksi_model.dart';

class BudgetRepository {
  BudgetRepository(this._db);
  final GemiDatabase _db;

  /// Plafon per kategori untuk satu bulan: {category_id: amount}.
  Future<Map<int, int>> plafon(String bulan) async {
    final rows = await (_db.select(
      _db.budgets,
    )..where((b) => b.month.equals(bulan))).get();
    return {for (final r in rows) r.categoryId: r.amount};
  }

  /// Pengeluaran per kategori dalam satu bulan: {category_id: total}.
  Future<Map<int, int>> pakai(String bulan) async {
    final t = _db.transactions;
    final total = t.amount.sum();
    final q = _db.selectOnly(t)
      ..addColumns([t.categoryId, total])
      ..where(
        t.type.equalsValue(JenisTransaksi.expense) & t.date.like('$bulan-%'),
      )
      ..groupBy([t.categoryId]);
    final rows = await q.get();
    return {for (final r in rows) r.read(t.categoryId)!: r.read(total) ?? 0};
  }

  /// Ganti seluruh plafon bulan itu. Nilai 0 = hapus baris.
  Future<void> simpan(String bulan, Map<int, int> plafon) => _db.transaction(
    () async {
      await (_db.delete(_db.budgets)..where((b) => b.month.equals(bulan))).go();
      await _db.batch((b) {
        for (final e in plafon.entries) {
          if (e.value > 0) {
            b.insert(
              _db.budgets,
              BudgetsCompanion.insert(
                categoryId: e.key,
                month: bulan,
                amount: e.value,
              ),
            );
          }
        }
      });
    },
  );

  /// Kategori pengeluaran urut sort_order; [termasukTersembunyi] untuk halaman budget
  /// (yang disembunyikan tapi sudah terpakai tetap tampil), false untuk form Ubah budget.
  Future<List<Kategori>> kategoriKeluar({bool termasukTersembunyi = false}) =>
      (_db.select(_db.categories)
            ..where(
              (k) =>
                  k.type.equalsValue(JenisKategori.expense) &
                  (termasukTersembunyi
                      ? const Constant(true)
                      : k.isHidden.equals(false)),
            )
            ..orderBy([
              (k) => OrderingTerm(expression: k.sortOrder),
              (k) => OrderingTerm(expression: k.id),
            ]))
          .get();
}
