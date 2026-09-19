import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../budget/budget_model.dart';
import '../kantong/kantong_model.dart';
import '../kategori/kategori_model.dart';
import '../transaksi/transaksi_model.dart';

part 'database.g.dart';

/// Satu database SQLite untuk seluruh app. Tabel didaftarkan per fitur.
/// Migrasi: naikkan [schemaVersion] dan tambah langkah onUpgrade; mulai berlaku
/// setelah 0.1 terpasang di HP sungguhan. Sebelum itu, ubah skema = hapus app.
@DriftDatabase(tables: [Accounts, Categories, Transactions, Budgets])
class GemiDatabase extends _$GemiDatabase {
  /// Untuk test: [executor] in-memory. Produksi lewat [buka].
  GemiDatabase(super.executor);

  /// Buka file DB terenkripsi SQLCipher. Kunci 256-bit acak, dibuat sekali,
  /// hidup hanya di Keystore/Keychain (BRD: Arsitektur & keamanan).
  static Future<GemiDatabase> buka() async {
    final kunci = await _kunciDb();
    return GemiDatabase(
      driftDatabase(
        name: 'gemi',
        native: DriftNativeOptions(
          setup: (db) {
            // Raw key hex: SQLCipher pakai langsung tanpa KDF; bukan passphrase.
            db.execute("PRAGMA key = \"x'$kunci'\"");
            if (db.select('PRAGMA cipher_version').isEmpty) {
              throw StateError(
                'database: SQLCipher tidak aktif, DB tidak terenkripsi',
              );
            }
          },
        ),
      ),
    );
  }

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
            CategoriesCompanion.insert(
              name: k.nama,
              type: k.jenis,
              color: k.warna,
              isDefault: const Value(true),
              sortOrder: Value(i),
            ),
          );
        }
      });
    },
  );
}

/// Kunci DB dari secure storage; dibuat acak kalau belum ada. 64 hex = 32 byte.
/// resetOnError false: kalau Keystore gagal dibaca, lebih baik error daripada
/// kunci diganti diam-diam dan seluruh data tidak terbaca.
Future<String> _kunciDb() async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
  );
  const nama = 'db_key';
  final ada = await storage.read(key: nama);
  if (ada != null) return ada;
  final r = Random.secure();
  final baru = List.generate(
    32,
    (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  await storage.write(key: nama, value: baru);
  return baru;
}
