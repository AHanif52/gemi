import 'package:drift/drift.dart';

import '../app/database.dart';

/// Tabel `budgets`: plafon bulanan per kategori pengeluaran (FR-06).
/// Unik per (category_id, month); month = YYYY-MM.
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer()();
  TextColumn get month => text()();
  IntColumn get amount => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {categoryId, month},
      ];
}

/// Satu baris halaman budget: kategori + plafon + terpakai. plafon 0 = tanpa budget.
class BarisBudget {
  const BarisBudget({required this.kategori, required this.plafon, required this.pakai});
  final Kategori kategori;
  final int plafon, pakai;

  int get sisa => plafon - pakai;
  bool get lewat => plafon > 0 && pakai > plafon;
  bool get hampir => plafon > 0 && !lewat && pakai * 100 >= plafon * 80;
  double get porsi => plafon == 0 ? 0 : (pakai / plafon).clamp(0, 1);
}

/// Ringkasan satu bulan: baris per kategori + total.
class DataBulan {
  const DataBulan(this.bulan, this.baris);
  final String bulan;
  final List<BarisBudget> baris;

  int get totalPlafon => baris.fold(0, (a, b) => a + b.plafon);
  int get totalPakai => baris.where((b) => b.plafon > 0).fold(0, (a, b) => a + b.pakai);
  int get sisa => totalPlafon - totalPakai;
  bool get adaBudget => totalPlafon > 0;
}
