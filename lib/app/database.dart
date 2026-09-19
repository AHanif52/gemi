import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../kantong/kantong_model.dart';

part 'database.g.dart';

/// Satu database SQLite untuk seluruh app. Tabel didaftarkan per fitur.
/// Migrasi: naikkan [schemaVersion] dan tambah langkah di [migration].
// ponytail: belum SQLCipher; enkripsi + kunci di Keystore ditambah di langkah keamanan 0.1.
@DriftDatabase(tables: [Accounts])
class GemiDatabase extends _$GemiDatabase {
  GemiDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'gemi'));

  @override
  int get schemaVersion => 1;
}
