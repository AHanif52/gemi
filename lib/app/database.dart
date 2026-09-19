import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../kantong/kantong_model.dart';
import '../kategori/kategori_model.dart';
import '../transaksi/transaksi_model.dart';

part 'database.g.dart';

/// Satu database SQLite untuk seluruh app. Tabel didaftarkan per fitur.
/// Migrasi: naikkan [schemaVersion] dan tambah langkah onUpgrade; mulai berlaku
/// setelah 0.1 terpasang di HP sungguhan. Sebelum itu, ubah skema = hapus app.
// ponytail: belum SQLCipher; enkripsi + kunci di Keystore ditambah di langkah keamanan 0.1.
@DriftDatabase(tables: [Accounts, Categories, Transactions])
class GemiDatabase extends _$GemiDatabase {
  GemiDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'gemi'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // FR-05: kategori bawaan terisi otomatis saat pertama install.
          await batch((b) {
            for (final (i, k) in kategoriBawaan.indexed) {
              b.insert(
                categories,
                CategoriesCompanion.insert(name: k.nama, type: k.jenis, color: k.warna, isDefault: const Value(true), sortOrder: Value(i)),
              );
            }
          });
        },
      );
}
