import 'package:drift/drift.dart';

enum JenisKategori { income, expense }

/// Tabel `categories`. Bawaan tidak bisa dihapus, hanya disembunyikan (FR-05).
/// `color` = indeks 0..5 ke warna kategori di theme (cat-1..cat-5, cat-other).
@DataClassName('Kategori')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<JenisKategori>()();
  IntColumn get color => integer()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Kategori bawaan, diisi sekali saat database dibuat. Urutan = sort_order.
const kategoriBawaan = [
  (nama: 'Makan', jenis: JenisKategori.expense, warna: 0),
  (nama: 'Transport', jenis: JenisKategori.expense, warna: 1),
  (nama: 'Belanja', jenis: JenisKategori.expense, warna: 2),
  (nama: 'Tagihan', jenis: JenisKategori.expense, warna: 3),
  (nama: 'Hiburan', jenis: JenisKategori.expense, warna: 4),
  (nama: 'Kesehatan', jenis: JenisKategori.expense, warna: 5),
  (nama: 'Lainnya', jenis: JenisKategori.expense, warna: 5),
  (nama: 'Gaji', jenis: JenisKategori.income, warna: 0),
  (nama: 'Bonus', jenis: JenisKategori.income, warna: 0),
  (nama: 'Lainnya', jenis: JenisKategori.income, warna: 5),
];
