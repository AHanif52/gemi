import 'package:drift/drift.dart';

/// Jenis kantong. Disimpan sebagai string di kolom `type` (bank/emoney/cash).
enum JenisKantong {
  bank('Bank'),
  emoney('E-money'),
  cash('Tunai');

  const JenisKantong(this.label);
  final String label;
}

/// Tabel `accounts` (BRD: Model data). Saldo tidak disimpan;
/// dihitung repository = initial_balance + transaksi di kantong ini.
@DataClassName('Kantong')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<JenisKantong>()();
  IntColumn get initialBalance => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}
