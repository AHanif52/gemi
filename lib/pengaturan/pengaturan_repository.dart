import '../app/database.dart';

class PengaturanRepository {
  PengaturanRepository(this._db);
  final GemiDatabase _db;

  Future<String?> baca(String key) async => (await (_db.select(
    _db.settings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> tulis(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
