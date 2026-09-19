import 'package:drift/drift.dart';

import '../app/database.dart';

enum JenisTransaksi {
  expense('Pengeluaran'),
  income('Pemasukan'),
  transfer('Transfer');

  const JenisTransaksi(this.label);
  final String label;
}

/// Tabel `transactions` (BRD: Model data). amount > 0 selalu; tanda ditentukan `type`.
/// transfer: wajib to_account_id, tanpa category_id. income/expense: sebaliknya.
/// `date` = YYYY-MM-DD waktu lokal, disimpan teks supaya bisa dibandingkan langsung di SQL.
@DataClassName('Transaksi')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => textEnum<JenisTransaksi>()();
  IntColumn get amount => integer()();
  IntColumn get accountId => integer()();
  IntColumn get toAccountId => integer().nullable()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get date => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Satu baris daftar: transaksi + nama kategori/kantong hasil JOIN. Dipakai screen.
class TransaksiBaris {
  const TransaksiBaris(this.t, {this.kategori, required this.kantong, this.kantongTujuan});
  final Transaksi t;
  final Kategori? kategori;
  final Kantong kantong;
  final Kantong? kantongTujuan;

  /// Judul baris: catatan, kalau kosong nama kategori / "Ke [kantong]".
  String get judul => t.note?.isNotEmpty == true
      ? t.note!
      : t.type == JenisTransaksi.transfer
          ? 'Ke ${kantongTujuan?.name ?? '?'}'
          : kategori?.name ?? '?';

  String get sub =>
      t.type == JenisTransaksi.transfer ? '${kantong.name} ke ${kantongTujuan?.name ?? '?'}' : '${kategori?.name ?? '?'} · ${kantong.name}';
}
