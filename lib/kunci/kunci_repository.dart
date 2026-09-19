import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../pengaturan/pengaturan_repository.dart';

/// Simpan/cek PIN dan preferensi kunci (FR-16).
/// Hash PIN (Argon2id + salt) hidup di Keystore/Keychain; preferensi kecil
/// (aktif, biometrik, kunci otomatis, hitungan gagal) di tabel settings.
/// PIN terpisah dari kunci DB: PIN hanya membuka layar.
class KunciRepository {
  KunciRepository(this._prefs, {FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: false),
          );

  final PengaturanRepository _prefs;
  final FlutterSecureStorage _storage;

  static const _kHash = 'pin_hash', _kSalt = 'pin_salt';
  // ponytail: parameter lebih ringan dari backup karena dipanggil tiap buka app;
  // PIN 4 angka dilindungi jeda 30 detik berlipat, bukan oleh kekuatan hash.
  static const _memoryKb = 8 * 1024, _iterations = 2;

  Future<List<int>> _hash(String pin, List<int> salt) async {
    final k = await Argon2id(
      memory: _memoryKb,
      iterations: _iterations,
      parallelism: 1,
      hashLength: 32,
    ).deriveKeyFromPassword(password: pin, nonce: salt);
    return k.extractBytes();
  }

  Future<bool> get adaPin async => await _storage.read(key: _kHash) != null;

  Future<void> simpanPin(String pin) async {
    final r = Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => r.nextInt(256)));
    await _storage.write(key: _kSalt, value: base64Encode(salt));
    await _storage.write(
      key: _kHash,
      value: base64Encode(await _hash(pin, salt)),
    );
  }

  Future<bool> cocok(String pin) async {
    final salt = await _storage.read(key: _kSalt);
    final hash = await _storage.read(key: _kHash);
    if (salt == null || hash == null) return false;
    final h = await _hash(pin, base64Decode(salt));
    // Bandingkan seluruh byte, tidak berhenti di byte pertama yang beda.
    final target = base64Decode(hash);
    var beda = h.length ^ target.length;
    for (var i = 0; i < h.length && i < target.length; i++) {
      beda |= h[i] ^ target[i];
    }
    return beda == 0;
  }

  Future<void> hapusPin() async {
    await _storage.delete(key: _kHash);
    await _storage.delete(key: _kSalt);
  }

  // Preferensi di tabel settings: kunci.aktif, kunci.biometrik,
  // kunci.otomatis (detik), kunci.gagal, kunci.jedaSampai (epoch ms).
  Future<String?> baca(String k) => _prefs.baca('kunci.$k');
  Future<void> tulis(String k, String v) => _prefs.tulis('kunci.$k', v);
}
