import 'package:drift/drift.dart';

/// Tabel key-value untuk preferensi kecil (backup terakhir, jam pengingat, dst.).
/// Menghindari package prefs terpisah (NFR-12).
@DataClassName('Setelan')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
